package com.springmvc.service;

import com.springmvc.model.Farmer;
import com.springmvc.model.FarmerImage;
import com.springmvc.model.HibernateConnection;
import jakarta.servlet.ServletContext;
import org.hibernate.Session;
import org.hibernate.Transaction;
import org.hibernate.query.Query;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.util.*;

@Service
public class FarmerImageService {

    // ตรงกับ WebConfig: /uploads/** -> file:///D:/Toos/png/
    private static final Path UPLOADS_ROOT = Paths.get("D:/Toos/png");

    private static final long MAX_SIZE = 5L * 1024 * 1024;
    private static final Set<String> ALLOWED = Set.of("image/jpeg","image/png","image/webp");

    // ========== Farmer ==========
    public Farmer findFarmerById(String farmerId) {
        if (farmerId == null || farmerId.trim().isEmpty()) return null;
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            return s.get(Farmer.class, farmerId);
        }
    }

    public Farmer findFarmerByEmail(String email) {
        if (email == null || email.trim().isEmpty()) return null;
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            return s.createQuery("from Farmer where lower(email) = :em", Farmer.class)
                    .setParameter("em", email.trim().toLowerCase(Locale.ROOT))
                    .setMaxResults(1)
                    .uniqueResult();
        } catch (Exception ignore) {
            try (Session s2 = HibernateConnection.getSessionFactory().openSession()) {
                return s2.createQuery("from Farmer where lower(mail) = :em", Farmer.class)
                        .setParameter("em", email.trim().toLowerCase(Locale.ROOT))
                        .setMaxResults(1)
                        .uniqueResult();
            } catch (Exception e2) { return null; }
        }
    }

    // ========== Gallery ==========
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

    /** เวอร์ชันเดิม (คงไว้เพื่อความเข้ากันได้) */
    public void deleteGalleryByIds(String farmerId, List<Long> idsToDelete,
                                   boolean deleteFiles, ServletContext ctx) {
        deleteGalleryByIdsCount(farmerId, idsToDelete, deleteFiles, ctx);
    }
    /** เวอร์ชันใหม่: คืนจำนวนรายการที่ลบ */
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
                    try { Files.deleteIfExists(abs); } catch (Exception ignored) {}
                }
            }
            for (FarmerImage fi : doomed) { s.remove(fi); n++; }

            tx.commit();
            return n;
        }
    }

    /** เวอร์ชันเดิม (คงไว้เพื่อความเข้ากันได้) */
    public void reorderKeptImages(String farmerId, List<Long> orderedIds) {
        reorderKeptImagesCount(farmerId, orderedIds);
    }
    /** เวอร์ชันใหม่: คืนจำนวนรายการที่ถูกอัปเดต sortOrder */
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

    /** เวอร์ชันเดิม: คืนรายการที่บันทึก (คงไว้) */
    public List<FarmerImage> saveNewGalleryImages(String farmerId,
                                                  List<MultipartFile> files,
                                                  ServletContext ctx) {
        List<MultipartFile> list = (files == null) ? List.of()
                : files.stream().filter(Objects::nonNull).filter(f -> !f.isEmpty()).toList();
        if (list.isEmpty()) return List.of();

        Path dir = ensureUploadsDir("farmers", farmerId, "gallery");
        List<FarmerImage> saved = new ArrayList<>();

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();

            Integer base = s.createQuery(
                    "select coalesce(max(sortOrder), -1) from FarmerImage where farmerId = :fid",
                    Integer.class
            ).setParameter("fid", farmerId).uniqueResult();
            int sort = (base == null ? -1 : base) + 1;

            for (MultipartFile mf : list) {
                if (!isAllowedImage(mf)) continue;

                String ext = extFrom(mf);
                String filename = UUID.randomUUID().toString().replace("-", "") + (ext.isEmpty() ? "" : ("."+ext));
                Path abs = dir.resolve(filename);
                Files.copy(mf.getInputStream(), abs, StandardCopyOption.REPLACE_EXISTING);

                // บันทึกเป็น path เริ่มด้วย /uploads/... ให้ตรง WebConfig
                String relative = ("/" + Paths.get("uploads","farmers", farmerId, "gallery", filename)
                        .toString().replace("\\","/"));

                FarmerImage fi = new FarmerImage();
                fi.setFarmerId(farmerId);
                fi.setImageUrl(relative);
                fi.setSortOrder(sort++);
                fi.setCreatedAt(LocalDateTime.now());

                s.persist(fi);
                saved.add(fi);
            }

            tx.commit();
        } catch (IOException e) {
            throw new RuntimeException("บันทึกรูปแกลเลอรีไม่สำเร็จ", e);
        }

        return saved;
    }
    /** เวอร์ชันใหม่: คืนจำนวนรูปที่บันทึก */
    public int saveNewGalleryImagesCount(String farmerId,
                                         List<MultipartFile> files,
                                         ServletContext ctx) {
        return saveNewGalleryImages(farmerId, files, ctx).size();
    }

    // ========== Profile & Slip ==========
    public String saveProfileImage(String farmerId, MultipartFile file, ServletContext ctx) {
        if (file == null || file.isEmpty()) return null;
        if (!isAllowedImage(file)) throw new RuntimeException("ไฟล์โปรไฟล์ไม่ถูกต้อง");

        Path dir = ensureUploadsDir("farmers", farmerId, "profile");
        String ext = extFrom(file);
        String filename = "profile_" + System.currentTimeMillis() + (ext.isEmpty() ? "" : ("."+ext));
        Path abs = dir.resolve(filename);

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Files.copy(file.getInputStream(), abs, StandardCopyOption.REPLACE_EXISTING);

            String relative = ("/" + Paths.get("uploads","farmers", farmerId, "profile", filename)
                    .toString().replace("\\","/"));

            Transaction tx = s.beginTransaction();
            Farmer f = s.get(Farmer.class, farmerId);
            if (f != null) {
                f.setImageF(relative);
                s.merge(f);
            }
            tx.commit();
            return relative;
        } catch (IOException e) {
            throw new RuntimeException("บันทึกรูปโปรไฟล์ไม่สำเร็จ", e);
        }
    }

    public String saveSlipImage(String farmerId, MultipartFile file, ServletContext ctx) {
        if (file == null || file.isEmpty()) return null;
        if (!isAllowedImage(file)) throw new RuntimeException("ไฟล์สลิปไม่ถูกต้อง");

        Path dir = ensureUploadsDir("farmers", farmerId, "slip");
        String ext = extFrom(file);
        String filename = "slip_" + System.currentTimeMillis() + (ext.isEmpty() ? "" : ("."+ext));
        Path abs = dir.resolve(filename);

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Files.copy(file.getInputStream(), abs, StandardCopyOption.REPLACE_EXISTING);

            String relative = ("/" + Paths.get("uploads","farmers", farmerId, "slip", filename)
                    .toString().replace("\\","/"));

            Transaction tx = s.beginTransaction();
            Farmer f = s.get(Farmer.class, farmerId);
            if (f != null) {
                f.setSlipUrl(relative);
                s.merge(f);
            }
            tx.commit();
            return relative;
        } catch (IOException e) {
            throw new RuntimeException("บันทึกรูปสลิปไม่สำเร็จ", e);
        }
    }

    /** เวอร์ชันเดิม (คงไว้) */
    public void updateFarmerBasic(Farmer f) {
        updateFarmerBasicReturn(f);
    }
    /** เวอร์ชันใหม่: ใช้ HQL update แล้วคืนว่ามีการเปลี่ยนจริงไหม */
    public boolean updateFarmerBasicReturn(Farmer f) {
        if (f == null || f.getFarmerId() == null || f.getFarmerId().trim().isEmpty()) return false;
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();
            Query<?> q = s.createQuery("""
                update Farmer
                   set farmName     = :fn,
                       email        = :em,
                       address      = :ad,
                       phoneNumber  = :ph,
                       farmLocation = :fl,
                       password     = :pw
                 where farmerId     = :fid
            """);
            q.setParameter("fn",  nz(f.getFarmName()));
            q.setParameter("em",  nz(f.getEmail()));
            q.setParameter("ad",  nz(f.getAddress()));
            q.setParameter("ph",  nz(f.getPhoneNumber()));
            q.setParameter("fl",  nz(f.getFarmLocation()));
            q.setParameter("pw",  nz(f.getPassword()));
            q.setParameter("fid", f.getFarmerId());
            int rows = q.executeUpdate();
            tx.commit();
            return rows > 0;
        }
    }

    // ========== helpers ==========
    private Path ensureUploadsDir(String... parts) {
        Path dir = UPLOADS_ROOT.resolve(Paths.get("", parts));
        try { Files.createDirectories(dir); } catch (IOException ignored) {}
        return dir;
    }

    private Path pathFromWeb(String webPath) {
        if (webPath == null) return UPLOADS_ROOT;
        String p = webPath.replace("\\","/");
        p = p.replaceFirst("^/+uploads/+",""); // ตัด /uploads/ ออก
        p = p.replaceFirst("^uploads/+","");   // หรือกรณีไม่มี / นำหน้า
        return UPLOADS_ROOT.resolve(p);
    }

    private boolean isAllowedImage(MultipartFile f) {
        if (f == null || f.isEmpty()) return false;
        String ct = Optional.ofNullable(f.getContentType()).orElse("").toLowerCase(Locale.ROOT);
        return ALLOWED.contains(ct) && f.getSize() <= MAX_SIZE;
    }

    private String extFrom(MultipartFile mf) {
        String ct = Optional.ofNullable(mf.getContentType()).orElse("");
        if (ct.contains("jpeg")) return "jpg";
        if (ct.contains("png"))  return "png";
        if (ct.contains("webp")) return "webp";
        String name = Optional.ofNullable(mf.getOriginalFilename()).orElse("");
        int dot = name.lastIndexOf('.');
        return (dot > 0 && dot < name.length()-1) ? name.substring(dot+1).toLowerCase(Locale.ROOT) : "";
    }

    private static String nz(String s){ return (s == null) ? "" : s.trim(); }
}
