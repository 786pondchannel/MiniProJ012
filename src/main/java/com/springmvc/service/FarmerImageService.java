package com.springmvc.service;

import com.springmvc.model.Farmer;
import com.springmvc.model.FarmerImage;
import com.springmvc.model.HibernateConnection;
import jakarta.servlet.ServletContext;
import org.hibernate.Session;
import org.hibernate.Transaction;
import org.hibernate.query.Query;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.util.*;

@Service
public class FarmerImageService {

    /* ---------- uploads root: ใช้ UPLOAD_DIR ถ้าไม่ตั้งจะเดาให้ ---------- */
    private static Path resolveUploadsRoot() {
        String env = System.getenv("UPLOAD_DIR");
        if (env != null && !env.isBlank()) return Paths.get(env).toAbsolutePath().normalize();
        String os = System.getProperty("os.name", "").toLowerCase(Locale.ROOT);
        if (os.contains("win")) return Paths.get("D:/Toos/png").toAbsolutePath().normalize();
        return Paths.get("/app/uploads").toAbsolutePath().normalize();
    }
    private static final Path UPLOADS_ROOT = resolveUploadsRoot();

    private static final long MAX_SIZE = 5L * 1024 * 1024;
    private static final Set<String> ALLOWED = Set.of("image/jpeg","image/png","image/webp");

    /* ================= Farmer basic ================= */

    public Farmer findFarmerById(String farmerId) {
        if (!StringUtils.hasText(farmerId)) return null;
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            return s.get(Farmer.class, farmerId);
        }
    }

    public Farmer findFarmerByEmail(String email) {
        if (!StringUtils.hasText(email)) return null;
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            return s.createQuery("from Farmer where lower(email) = :em", Farmer.class)
                    .setParameter("em", email.trim().toLowerCase(Locale.ROOT))
                    .setMaxResults(1)
                    .uniqueResult();
        } catch (Exception e) {
            return null;
        }
    }

    /** ใช้ merge เพื่ออัปเดตทุกฟิลด์ (รวม imageF / slipUrl) ตามที่ตั้งค่าใน entity */
    public boolean updateFarmerBasicReturn(Farmer f) {
        if (f == null || !StringUtils.hasText(f.getFarmerId())) return false;
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();
            s.merge(f);
            tx.commit();
            return true;
        } catch (Exception e) {
            throw new RuntimeException("DB error while updating farmer: " + e.getMessage(), e);
        }
    }

    /* ================= Gallery ================= */

    public List<FarmerImage> findGallery(String farmerId) {
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            return s.createQuery(
                    "from FarmerImage where farmerId = :fid order by sortOrder asc, id asc",
                    FarmerImage.class
            ).setParameter("fid", farmerId).getResultList();
        }
    }

    public int countGallery(String farmerId) {
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Long c = s.createQuery(
                    "select count(fi.id) from FarmerImage fi where fi.farmerId = :fid",
                    Long.class
            ).setParameter("fid", farmerId).uniqueResult();
            return c == null ? 0 : c.intValue();
        }
    }

    public int deleteGalleryByIdsCount(String farmerId, List<Long> idsToDelete,
                                       boolean deleteFiles, ServletContext ctx) {
        if (idsToDelete == null || idsToDelete.isEmpty()) return 0;

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();

            List<FarmerImage> doomed = s.createQuery(
                    "from FarmerImage where farmerId = :fid and id in (:ids)",
                    FarmerImage.class
            ).setParameter("fid", farmerId)
             .setParameterList("ids", idsToDelete)
             .getResultList();

            int n = 0;
            if (deleteFiles) {
                for (FarmerImage fi : doomed) {
                    Path abs = pathFromWeb(fi.getImageUrl());
                    try { if (abs != null) Files.deleteIfExists(abs); } catch (Exception ignored) {}
                }
            }
            for (FarmerImage fi : doomed) { s.remove(fi); n++; }

            tx.commit();
            return n;
        }
    }

    public int reorderKeptImagesCount(String farmerId, List<Long> orderedIds) {
        if (orderedIds == null || orderedIds.isEmpty()) return 0;
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();
            int idx = 0, touched = 0;
            for (Long id : orderedIds) {
                Query<?> q = s.createQuery(
                        "update FarmerImage set sortOrder = :ord where id = :id and farmerId = :fid"
                );
                q.setParameter("ord", idx++);
                q.setParameter("id", id);
                q.setParameter("fid", farmerId);
                touched += q.executeUpdate();
            }
            tx.commit();
            return touched;
        }
    }

    public int saveNewGalleryImagesCount(String farmerId, List<MultipartFile> files, ServletContext ctx) {
        if (files == null || files.isEmpty()) return 0;

        Path dir = ensureUploadsDir("farmers", farmerId, "gallery");
        int saved = 0;

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();

            Integer base = s.createQuery(
                    "select coalesce(max(sortOrder), -1) from FarmerImage where farmerId = :fid",
                    Integer.class
            ).setParameter("fid", farmerId).uniqueResult();
            int sort = (base == null ? -1 : base) + 1;

            for (MultipartFile mf : files) {
                if (!isAllowedImage(mf)) continue;

                String filename = UUID.randomUUID().toString().replace("-", "") + "." + extFrom(mf);
                Path abs = dir.resolve(filename);
                try (InputStream in = mf.getInputStream()) {
                    Files.copy(in, abs, StandardCopyOption.REPLACE_EXISTING);
                }

                String web = "/uploads/" + UPLOADS_ROOT.relativize(abs).toString().replace("\\","/");
                FarmerImage fi = new FarmerImage();
                fi.setFarmerId(farmerId);
                fi.setImageUrl(web);
                fi.setSortOrder(sort++);
                fi.setCreatedAt(LocalDateTime.now());
                s.persist(fi);
                saved++;
            }

            tx.commit();
        } catch (IOException e) {
            throw new RuntimeException("บันทึกรูปแกลเลอรีไม่สำเร็จ", e);
        }
        return saved;
    }

    /* ================= Single images (profile / slip) ================= */

    public String saveProfileImage(String farmerId, MultipartFile file, ServletContext ctx) {
        if (!isAllowedImage(file)) throw new RuntimeException("ไฟล์โปรไฟล์ไม่ถูกต้อง");

        Path dir = ensureUploadsDir("farmers", farmerId, "profile");
        String filename = "profile_" + System.currentTimeMillis() + "." + extFrom(file);
        Path abs = dir.resolve(filename);

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            try (InputStream in = file.getInputStream()) {
                Files.copy(in, abs, StandardCopyOption.REPLACE_EXISTING);
            }
            String web = "/uploads/" + UPLOADS_ROOT.relativize(abs).toString().replace("\\","/");

            Transaction tx = s.beginTransaction();
            Farmer f = s.get(Farmer.class, farmerId);
            if (f != null) {
                f.setImageF(web);
                s.merge(f);
            }
            tx.commit();
            return web;
        } catch (IOException e) {
            throw new RuntimeException("บันทึกรูปโปรไฟล์ไม่สำเร็จ", e);
        }
    }

    public String saveSlipImage(String farmerId, MultipartFile file, ServletContext ctx) {
        if (!isAllowedImage(file)) throw new RuntimeException("ไฟล์สลิปไม่ถูกต้อง");

        Path dir = ensureUploadsDir("farmers", farmerId, "slip");
        String filename = "slip_" + System.currentTimeMillis() + "." + extFrom(file);
        Path abs = dir.resolve(filename);

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            try (InputStream in = file.getInputStream()) {
                Files.copy(in, abs, StandardCopyOption.REPLACE_EXISTING);
            }
            String web = "/uploads/" + UPLOADS_ROOT.relativize(abs).toString().replace("\\","/");

            Transaction tx = s.beginTransaction();
            Farmer f = s.get(Farmer.class, farmerId);
            if (f != null) {
                f.setSlipUrl(web);
                s.merge(f);
            }
            tx.commit();
            return web;
        } catch (IOException e) {
            throw new RuntimeException("บันทึกรูปสลิปไม่สำเร็จ", e);
        }
    }

    /* ================= helpers ================= */

    private Path ensureUploadsDir(String... parts) {
        Path dir = UPLOADS_ROOT.resolve(Paths.get("", parts)).normalize();
        try { Files.createDirectories(dir); } catch (IOException ignore) {}
        return dir;
    }

    private Path pathFromWeb(String webPath) {
        if (!StringUtils.hasText(webPath)) return null;
        String p = webPath.trim().replace("\\","/");
        if (p.startsWith("/")) p = p.substring(1);
        if (p.startsWith("uploads/")) p = p.substring("uploads/".length());
        return UPLOADS_ROOT.resolve(p).normalize();
    }

    private boolean isAllowedImage(MultipartFile f) {
        if (f == null || f.isEmpty()) return false;
        String ct = Optional.ofNullable(f.getContentType()).orElse("").toLowerCase(Locale.ROOT);
        boolean ok = ALLOWED.contains(ct);
        if (!ok) {
            String name = Optional.ofNullable(f.getOriginalFilename()).orElse("").toLowerCase(Locale.ROOT);
            ok = name.endsWith(".jpg") || name.endsWith(".jpeg") || name.endsWith(".png") || name.endsWith(".webp");
        }
        return ok && f.getSize() <= MAX_SIZE;
    }

    private String extFrom(MultipartFile mf) {
        String ct = Optional.ofNullable(mf.getContentType()).orElse("").toLowerCase(Locale.ROOT);
        if (ct.contains("jpeg")) return "jpg";
        if (ct.contains("png"))  return "png";
        if (ct.contains("webp")) return "webp";
        String name = Optional.ofNullable(mf.getOriginalFilename()).orElse("");
        int dot = name.lastIndexOf('.');
        return (dot > 0 && dot < name.length()-1) ? name.substring(dot+1).toLowerCase(Locale.ROOT) : "jpg";
    }
}
