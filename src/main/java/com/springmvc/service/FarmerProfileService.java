package com.springmvc.service;

import com.springmvc.model.Farmer;
import com.springmvc.model.FarmerImage;
import com.springmvc.model.Review;
import com.springmvc.model.HibernateConnection;
import jakarta.servlet.ServletContext;
import org.hibernate.Session;
import org.hibernate.Transaction;
import org.hibernate.query.Query;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.*;
import java.sql.*;
import java.sql.Date;
import java.time.LocalDate;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Stream;

@Service
public class FarmerProfileService {

    /* ================== โฟลเดอร์จริงที่แมปเป็น /uploads/** ================== */
    /** <-- แก้ให้ตรงกับเครื่องคุณ (ของเดิมใช้ D:/Toos/png) */
    private static final Path UPLOADS_ROOT = Paths.get("D:/Toos/png");

    /* อนุญาตไฟล์รูป */
    private static final long MAX_SIZE = 5L * 1024 * 1024;
    private static final Set<String> ALLOWED = Set.of("image/jpeg","image/png","image/webp");

    /** โฟลเดอร์/รูปแบบที่คาดว่าเก็บ QR ร้าน */
    private static final String[] QR_DIRS = { "slip", "qr", "payment", "farmer_qr" };
    private static final String[] IMG_EXT = { ".png",".jpg",".jpeg",".webp",".gif" };

    /* ========= DTO รวมข้อมูลให้ Controller เติมลง Model ========= */
    public static class ProfileData {
        public final Farmer farmer;
        public final double avgRating;
        public final int reviewCount;
        public final List<Review> reviews;
        public final List<Map<String, Object>> products;
        public final List<String> gallery;       // แกลเลอรีจากไฟล์
        public final String paymentSlipUrl;

        public ProfileData(Farmer farmer, double avgRating, int reviewCount,
                           List<Review> reviews, List<Map<String, Object>> products,
                           List<String> gallery, String paymentSlipUrl) {
            this.farmer = farmer;
            this.avgRating = avgRating;
            this.reviewCount = reviewCount;
            this.reviews = reviews;
            this.products = products;
            this.gallery = gallery;
            this.paymentSlipUrl = paymentSlipUrl;
        }
    }

    /* ======================= แกนหลักที่หน้าโปรไฟล์ใช้ ======================= */

    /** รวมทุกอย่างที่หน้า JSP ต้องใช้ไว้ในครั้งเดียว */
    public ProfileData getProfileData(String farmerId, String ctx) throws Exception {
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Farmer farmer = loadFarmer(s, farmerId);

            List<Review> reviews = loadReviewsByFarmer(s, farmerId);
            double avg = 0d;
            if (!reviews.isEmpty()) {
                long sum = 0; for (Review r : reviews) sum += r.getRating();
                avg = sum / (double) reviews.size();
            }

            List<Map<String,Object>> products = loadProductsByFarmerFuzzy(s, farmerId, 48);
            normalizeProductImagesToUploads(products, ctx);

            // สร้างแกลเลอรีจากไฟล์ (โปรไฟล์ + รูปสินค้า)
            List<String> gallery = buildGalleryFilesOnly(farmer, products, ctx, 10);

            String paymentSlipUrl = resolveQrOrSlipUrl(farmer, farmerId, ctx);

            return new ProfileData(farmer, avg, reviews.size(), reviews, products, gallery, paymentSlipUrl);
        }
    }

    /** ให้ Controller เรียกหา Farmer ตรง ๆ */
    public Farmer findFarmerById(String farmerId) {
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            return s.get(Farmer.class, farmerId);
        }
    }

    /** ให้ Controller ใช้สตรีมภาพ QR โดยตรง (ถ้าต้องการ) */
    public Path findQrFile(String farmerId){
        if (!StringUtils.hasText(farmerId)) return null;
        for (String dir : QR_DIRS){
            // แบบโฟลเดอร์/{farmerId}/ไฟล์ใดก็ได้
            Path d1 = UPLOADS_ROOT.resolve(dir).resolve(farmerId);
            if (Files.isDirectory(d1)) {
                try (Stream<Path> st = Files.list(d1)) {
                    Optional<Path> any = st.filter(Files::isRegularFile).findFirst();
                    if (any.isPresent()) return any.get();
                } catch (IOException ignore) {}
            }
            // แบบโฟลเดอร์/{farmerId}.ext
            for (String ext : IMG_EXT){
                Path f = UPLOADS_ROOT.resolve(dir).resolve(farmerId + ext);
                if (Files.isRegularFile(f)) return f;
            }
        }
        return null;
    }

    /* ======================= Helpers: run SQL ผ่าน Hibernate ======================= */
    private <T> T withConn(Session s, Function<Connection, T> fn) {
        return s.doReturningWork(fn::apply);
    }

    /* ======================= โหลดข้อมูล (ผ่าน Hibernate connection) ======================= */

    private Farmer loadFarmer(Session s, String fid) {
        if (!StringUtils.hasText(fid)) return null;
        return withConn(s, conn -> {
            String[] tableNames = {"farmer", "Farmer"};
            String[] idCols     = {"farmer_id", "farmerId", "id", "uuid"};
            for (String t : tableNames) {
                for (String idc : idCols) {
                    String sql = "SELECT * FROM " + t + " WHERE " + idc + " = ? LIMIT 1";
                    try (PreparedStatement ps = conn.prepareStatement(sql)) {
                        ps.setString(1, fid);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) return mapFarmer(rs);
                        }
                    } catch (Exception ignore) {}
                }
            }
            return null;
        });
    }

    private List<Review> loadReviewsByFarmer(Session s, String fid) {
        return withConn(s, conn -> {
            String[] reviewTables  = {"review", "Review"};
            String[] productTables = {"product", "Product"};
            String[][] rCols = {
                {"review_id","rating","comment","review_date","member_id","product_id","order_id"},
                {"reviewId","rating","comment","reviewDate","memberId","productId","orderId"}
            };
            String[][] pCols = { {"product_id","farmer_id"}, {"productId","farmerId"} };

            for (String rt : reviewTables) {
                for (String pt : productTables) {
                    for (String[] RC : rCols) {
                        for (String[] PC : pCols) {
                            String sql =
                                "SELECT r."+RC[0]+", r."+RC[1]+", r."+RC[2]+", r."+RC[3]+", " +
                                "       r."+RC[4]+", r."+RC[5]+", r."+RC[6]+" " +
                                "FROM " + rt + " r JOIN " + pt + " p ON r."+RC[5]+" = p."+PC[0]+" " +
                                "WHERE p."+PC[1]+" = ? ORDER BY r."+RC[3]+" DESC";
                            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                                ps.setString(1, fid);
                                try (ResultSet rs = ps.executeQuery()) {
                                    List<Review> out = new ArrayList<>();
                                    while (rs.next()) {
                                        Review r = new Review();
                                        r.setReviewId(getS(rs,1));
                                        r.setRating(getI(rs,2,0));
                                        r.setComment(getS(rs,3));
                                        // ให้ตรง entity: LocalDate
                                        r.setReviewDate(getLD(rs,4));
                                        r.setMemberId(getS(rs,5));
                                        r.setProductId(getS(rs,6));
                                        r.setOrderId(getS(rs,7));
                                        out.add(r);
                                    }
                                    return out;
                                }
                            } catch (Exception ignore) {}
                        }
                    }
                }
            }
            return Collections.emptyList();
        });
    }

    /** ดึงสินค้าแบบพยายามทุกตาราง/คอลัมน์ที่เป็นไปได้ */
    private List<Map<String,Object>> loadProductsByFarmerFuzzy(Session s, String fid, int limit) {
        return withConn(s, conn -> {
            List<Map<String,Object>> out = new ArrayList<>();

            String[] pt = {"product","Product"};
            String[] idCols = {"farmer_id","farmerId","seller_id","sellerId","owner_id","ownerId","created_by","createdBy","member_id","memberId"};
            for (String t : pt) {
                for (String idc : idCols) {
                    String sql = "SELECT * FROM " + t + " WHERE " + idc + " = ? ORDER BY 1 DESC LIMIT " + limit;
                    if (fetchProducts(conn, out, sql, fid)) return out;
                }
            }

            String[] link = {"farmer_product","product_farmer","seller_product","product_seller",
                             "FarmerProduct","ProductFarmer","SellerProduct","ProductSeller"};
            String[][] pid = {{"product_id"},{"productId"}};
            String[][] fidCols = {{"farmer_id"},{"farmerId"},{"seller_id"},{"sellerId"}};
            for (String t : pt) {
                for (String lk : link) {
                    for (String[] pc : pid) {
                        for (String[] fc : fidCols) {
                            String sql =
                                "SELECT p.* FROM "+t+" p JOIN "+lk+" l ON l."+pc[0]+" = p."+pc[0]+" " +
                                "WHERE l."+fc[0]+" = ? ORDER BY 1 DESC LIMIT " + limit;
                            if (fetchProducts(conn, out, sql, fid)) return out;
                        }
                    }
                }
            }
            return out;
        });
    }

    private boolean fetchProducts(Connection conn, List<Map<String,Object>> out, String sql, String fid) {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, fid);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String,Object> p = new LinkedHashMap<>();
                    p.put("productId", any(rs,"product_id","productId","id"));
                    p.put("productName", any(rs,"product_name","productName","name","title"));
                    p.put("description", any(rs,"description","desc","detail"));
                    p.put("price", any(rs,"price","unit_price","unitPrice","amount"));

                    Object img = any(rs,"image_url","main_image","thumbnail","image","img","cover");
                    if (img != null) {
                        p.put("imageUrl", img);
                        p.putIfAbsent("mainImage", img);
                        p.putIfAbsent("thumbnail", img);
                        p.putIfAbsent("image", img);
                    }

                    // แนบรูปจากตาราง product_image(s)
                    List<Map<String,Object>> imgs = loadProductImagesById(conn, String.valueOf(p.get("productId")));
                    if (!imgs.isEmpty()) p.put("productImages", imgs);

                    out.add(p);
                }
            }
            return !out.isEmpty();
        } catch (Exception ignore) { return false; }
    }

    private List<Map<String,Object>> loadProductImagesById(Connection conn, String productId) {
        List<Map<String,Object>> out = new ArrayList<>();
        if (!StringUtils.hasText(productId)) return out;

        String[] imgTables = {"product_image", "product_images", "ProductImage", "ProductImages"};
        String[][] pidCols = {{"product_id"}, {"productId"}};
        String[][] urlCols = {{"url"}, {"image_url"}, {"imageUrl"}, {"path"}};

        for (String it : imgTables) {
            for (String[] pc : pidCols) {
                for (String[] uc : urlCols) {
                    String sql = "SELECT " + uc[0] + " FROM " + it + " WHERE " + pc[0] + " = ? ORDER BY 1";
                    try (PreparedStatement ps = conn.prepareStatement(sql)) {
                        ps.setString(1, productId);
                        try (ResultSet rs = ps.executeQuery()) {
                            while (rs.next()) {
                                String url = rs.getString(1);
                                if (StringUtils.hasText(url)) {
                                    Map<String,Object> m = new HashMap<>();
                                    m.put("url", url);
                                    out.add(m);
                                }
                            }
                            if (!out.isEmpty()) return out;
                        }
                    } catch (Exception ignore){}
                }
            }
        }
        return out;
    }

    /* ================== รูปจากไฟล์เท่านั้น (แปลงเป็น /uploads/**) ================== */

    public void normalizeProductImagesToUploads(List<Map<String,Object>> products, String ctx){
        if (products == null) return;
        for (Map<String,Object> p : products){
            p.put("imageUrl",  toUploadsUrl(str(p.get("imageUrl")),  ctx));
            p.put("mainImage", toUploadsUrl(str(p.get("mainImage")), ctx));
            p.put("thumbnail", toUploadsUrl(str(p.get("thumbnail")), ctx));
            p.put("image",     toUploadsUrl(str(p.get("image")),     ctx));

            Object imgs = p.get("productImages");
            if (imgs instanceof List) {
                List<?> li = (List<?>) imgs;
                List<Map<String,Object>> ret = new ArrayList<>();
                for (Object o : li){
                    if (o instanceof Map){
                        @SuppressWarnings("unchecked")
                        Map<String, Object> mp = (Map<String, Object>) o;
                        String u = str(mp.get("url"));
                        if (!StringUtils.hasText(u)) u = str(mp.get("imageUrl"));
                        if (!StringUtils.hasText(u)) u = str(mp.get("path"));
                        String web = toUploadsUrl(u, ctx);
                        if (web != null){ Map<String,Object> m2=new HashMap<>(); m2.put("url", web); ret.add(m2); }
                    }
                }
                p.put("productImages", ret);
            }
            Object pi = p.get("productImages");
            if (!StringUtils.hasText(str(p.get("imageUrl"))) && pi instanceof List) {
                List<?> li2 = (List<?>) pi;
                if (!li2.isEmpty() && li2.get(0) instanceof Map) {
                    @SuppressWarnings("unchecked")
                    Map<String,Object> mp = (Map<String,Object>) li2.get(0);
                    p.put("imageUrl", str(mp.get("url")));
                }
            }
        }
    }

    public List<String> buildGalleryFilesOnly(Farmer farmer, List<Map<String,Object>> products, String ctx, int maxN){
        LinkedHashSet<String> set = new LinkedHashSet<>();
        String fimg = toUploadsUrl(str(getField(farmer,"imageF")), ctx);
        if (fimg != null) set.add(fimg);

        if (products != null) {
            for (Map<String,Object> p : products) {
                if (set.size() >= maxN) break;
                String main = firstNonEmpty(str(p.get("imageUrl")), str(p.get("mainImage")), str(p.get("thumbnail")), str(p.get("image")));
                String web = toUploadsUrl(main, ctx);
                if (web != null) set.add(web);

                Object imgs = p.get("productImages");
                if (imgs instanceof Collection){
                    Collection<?> col = (Collection<?>) imgs;
                    for (Object im : col){
                        if (set.size() >= maxN) break;
                        String u = null;
                        if (im instanceof Map){
                            @SuppressWarnings("unchecked")
                            Map<String,Object> mp = (Map<String,Object>) im;
                            u = str(mp.get("url"));
                        } else {
                            u = str(im);
                        }
                        String ok = toUploadsUrl(u, ctx);
                        if (ok != null) set.add(ok);
                    }
                }
            }
        }
        return new ArrayList<>(set).subList(0, Math.min(set.size(), maxN));
    }

    public String resolveQrOrSlipUrl(Farmer f, String farmerId, String ctx){
        String raw = firstNonEmpty(
                str(getField(f,"slipUrl")), str(getField(f,"qrUrl")), str(getField(f,"qr_url")),
                str(getField(f,"qrPath")),   str(getField(f,"qr_path"))
        );
        String fromDb = toUploadsUrl(raw, ctx);
        if (fromDb != null) return fromDb;

        Path found = findQrFile(farmerId);
        if (found != null){
            String rel = toUploadsRelative(found);
            return StringUtils.hasText(rel) ? (ctx + "/uploads/" + rel) : null;
        }
        return null;
    }

    /* ================== แกลเลอรี (ตาราง farmer_images) ================== */

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

    public void deleteGalleryByIds(String farmerId, List<Long> idsToDelete, boolean deleteFiles) {
        if (idsToDelete == null || idsToDelete.isEmpty()) return;

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();

            List<FarmerImage> doomed = s.createQuery(
                    "from FarmerImage where farmerId = :fid and id in (:ids)",
                    FarmerImage.class
            ).setParameter("fid", farmerId)
             .setParameterList("ids", idsToDelete)
             .getResultList();

            if (deleteFiles) {
                for (FarmerImage fi : doomed) {
                    try {
                        Path abs = pathFromWeb(fi.getImageUrl());
                        if (abs != null) Files.deleteIfExists(abs);
                    } catch (Exception ignored) {}
                }
            }
            for (FarmerImage fi : doomed) s.remove(fi);

            tx.commit();
        }
    }

    public void reorderKeptImages(String farmerId, List<Long> orderedIds) {
        if (orderedIds == null || orderedIds.isEmpty()) return;

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();
            int idx = 0;
            for (Long id : orderedIds) {
                Query<?> q = s.createQuery(
                        "update FarmerImage set sortOrder = :ord where id = :id and farmerId = :fid"
                );
                q.setParameter("ord", idx++);
                q.setParameter("id",  id);
                q.setParameter("fid", farmerId);
                q.executeUpdate();
            }
            tx.commit();
        }
    }

    /** บันทึกภาพใหม่ลงแกลเลอรี (2 พารามิเตอร์) */
    public List<FarmerImage> saveNewGalleryImages(String farmerId, List<MultipartFile> files) {
        if (files == null || files.isEmpty()) return List.of();

        Path dir = ensureDirOnDisk("farmers", farmerId, "gallery");
        List<FarmerImage> saved = new ArrayList<>();

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();

            Integer base = s.createQuery(
                    "select coalesce(max(sortOrder), -1) from FarmerImage where farmerId = :fid",
                    Integer.class
            ).setParameter("fid", farmerId).uniqueResult();
            int sort = (base == null ? -1 : base) + 1;

            for (MultipartFile mf : files) {
                if (mf == null || mf.isEmpty()) continue;
                if (!isAllowedImage(mf)) continue;

                String ext = extFrom(mf);
                String filename = UUID.randomUUID().toString().replace("-", "") + (ext.isEmpty() ? "" : ("."+ext));
                Path abs = dir.resolve(filename);
                Files.copy(mf.getInputStream(), abs, StandardCopyOption.REPLACE_EXISTING);

                String relative = ("uploads/" + Paths.get("farmers", farmerId, "gallery", filename)
                        .toString().replace("\\","/"));

                FarmerImage fi = new FarmerImage();
                fi.setFarmerId(farmerId);
                fi.setImageUrl(relative);
                fi.setSortOrder(sort++);
                s.persist(fi);
                saved.add(fi);
            }

            tx.commit();
        } catch (IOException e) {
            throw new RuntimeException("บันทึกรูปแกลเลอรีไม่สำเร็จ", e);
        }

        return saved;
    }

    /** อัปโหลดรูปโปรไฟล์ร้าน (2 พารามิเตอร์) */
    public String saveProfileImage(String farmerId, MultipartFile file) {
        if (file == null || file.isEmpty()) return null;
        if (!isAllowedImage(file)) throw new RuntimeException("ไฟล์โปรไฟล์ไม่ถูกต้อง");

        Path dir = ensureDirOnDisk("farmers", farmerId, "profile");
        String ext = extFrom(file);
        String filename = "profile_" + System.currentTimeMillis() + (ext.isEmpty() ? "" : ("."+ext));
        Path abs = dir.resolve(filename);

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Files.copy(file.getInputStream(), abs, StandardCopyOption.REPLACE_EXISTING);

            String relative = ("uploads/" + Paths.get("farmers", farmerId, "profile", filename)
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

    /** อัปโหลดรูปสลิป/QR (2 พารามิเตอร์) */
    public String saveSlipImage(String farmerId, MultipartFile file) {
        if (file == null || file.isEmpty()) return null;
        if (!isAllowedImage(file)) throw new RuntimeException("ไฟล์สลิปไม่ถูกต้อง");

        Path dir = ensureDirOnDisk("farmers", farmerId, "slip");
        String ext = extFrom(file);
        String filename = "slip_" + System.currentTimeMillis() + (ext.isEmpty() ? "" : ("."+ext));
        Path abs = dir.resolve(filename);

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Files.copy(file.getInputStream(), abs, StandardCopyOption.REPLACE_EXISTING);

            String relative = ("uploads/" + Paths.get("farmers", farmerId, "slip", filename)
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

    /** อัปเดตข้อมูลพื้นฐานของ Farmer */
    public void updateFarmerBasic(Farmer f) {
        if (f == null || !StringUtils.hasText(f.getFarmerId())) return;
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();
            s.merge(f);
            tx.commit();
        }
    }

    /* ---------- OVERLOAD 3 พารามิเตอร์ (เพื่อไม่พัง Controller เดิมที่ส่ง ctx) ---------- */
    public List<FarmerImage> saveNewGalleryImages(String farmerId, List<MultipartFile> files, ServletContext ctx){
        return saveNewGalleryImages(farmerId, files);
    }
    public String saveProfileImage(String farmerId, MultipartFile file, ServletContext ctx){
        return saveProfileImage(farmerId, file);
    }
    public String saveSlipImage(String farmerId, MultipartFile file, ServletContext ctx){
        return saveSlipImage(farmerId, file);
    }
    public void deleteGalleryByIds(String farmerId, List<Long> idsToDelete, boolean deleteFiles, ServletContext ctx){
        deleteGalleryByIds(farmerId, idsToDelete, deleteFiles);
    }
    public Path ensureDir(ServletContext ctx, String... parts){
        return ensureDirOnDisk(parts);
    }

    /* ================== พาธ/ไฟล์ helper ================== */

    /** ใช้ตรวจไฟล์รูปที่อนุญาต + ขนาดไม่เกิน 5MB */
    private boolean isAllowedImage(MultipartFile f) {
        if (f == null || f.isEmpty()) return false;
        String ct = Optional.ofNullable(f.getContentType()).orElse("").toLowerCase(Locale.ROOT);
        if (ALLOWED.contains(ct) && f.getSize() <= MAX_SIZE) return true;

        // fallback: ตรวจจากนามสกุลไฟล์
        String name = Optional.ofNullable(f.getOriginalFilename()).orElse("").toLowerCase(Locale.ROOT);
        boolean extOk = name.endsWith(".jpg") || name.endsWith(".jpeg") || name.endsWith(".png") || name.endsWith(".webp");
        return extOk && f.getSize() <= MAX_SIZE;
    }

    /** แปลงพาธดิบ -> URL /uploads/** (เฉพาะไฟล์ที่มีจริงใต้ UPLOADS_ROOT) */
    private String toUploadsUrl(String raw, String ctx){
        if (!StringUtils.hasText(raw)) return null;
        String u = raw.trim().replace("\\","/");
        String low = u.toLowerCase(Locale.ROOT);

        // /uploads/** หรือ uploads/**
        if (u.startsWith("/uploads/")) {
            Path abs = UPLOADS_ROOT.resolve(u.substring("/uploads/".length())).normalize();
            return Files.isRegularFile(abs) ? (ctx + u) : null;
        }
        if (u.startsWith("uploads/")) {
            Path abs = UPLOADS_ROOT.resolve(u.substring("uploads/".length())).normalize();
            return Files.isRegularFile(abs) ? (ctx + "/" + u) : null;
        }

        // absolute (เช่น D:/Toos/png/...)
        if (low.matches("^[a-z]:/.*")) {
            Path p = Paths.get(u);
            if (Files.isRegularFile(p)) {
                String rel = toUploadsRelative(p);
                return StringUtils.hasText(rel) ? (ctx + "/uploads/" + rel) : null;
            }
            Path alt = UPLOADS_ROOT.resolve(u.replaceFirst("^[a-zA-Z]:/+", "")).normalize();
            if (Files.isRegularFile(alt)) {
                String rel = toUploadsRelative(alt);
                return StringUtils.hasText(rel) ? (ctx + "/uploads/" + rel) : null;
            }
            return null;
        }

        // relative (เช่น products/xxx.jpg)
        String rel = u.replaceFirst("^/*uploads/*",""); // กันพิมพ์ซ้ำ
        Path abs = UPLOADS_ROOT.resolve(rel).normalize();
        return Files.isRegularFile(abs) ? (ctx + "/uploads/" + rel) : null;
    }

    /** พาธย่อยใต้ uploads/ จากไฟล์ absolute ใน UPLOADS_ROOT */
    private String toUploadsRelative(Path absolute){
        try{
            Path root = UPLOADS_ROOT.toRealPath();
            Path ap   = absolute.toRealPath();
            if (ap.startsWith(root)){
                return root.relativize(ap).toString().replace("\\","/");
            }
        }catch(Exception ignore){}
        return null;
    }

    /** แปลง web path "uploads/..." หรือ "/uploads/..." -> absolute Path ใต้ UPLOADS_ROOT */
    private Path pathFromWeb(String webPath){
        if (!StringUtils.hasText(webPath)) return null;
        String p = webPath.trim().replace("\\","/");
        if (p.startsWith("/")) p = p.substring(1);
        if (p.startsWith("uploads/")) p = p.substring("uploads/".length());
        return UPLOADS_ROOT.resolve(p).normalize();
    }

    /** สร้างโฟลเดอร์ใต้ UPLOADS_ROOT */
    private Path ensureDirOnDisk(String... parts) {
        Path dir = UPLOADS_ROOT.resolve(Paths.get("", parts)).normalize();
        try { Files.createDirectories(dir); } catch (IOException ignore) {}
        return dir;
    }

    private String extFrom(MultipartFile mf) {
        String ct = Optional.ofNullable(mf.getContentType()).orElse("").toLowerCase(Locale.ROOT);
        if (ct.contains("jpeg")) return "jpg";
        if (ct.contains("png"))  return "png";
        if (ct.contains("webp")) return "webp";
        // fallback จากชื่อไฟล์
        String name = Optional.ofNullable(mf.getOriginalFilename()).orElse("");
        int dot = name.lastIndexOf('.');
        return (dot > 0 && dot < name.length()-1) ? name.substring(dot+1).toLowerCase(Locale.ROOT) : "";
    }

    /* ================== mapper / utils ================== */
    private Farmer mapFarmer(ResultSet rs) throws SQLException {
        Farmer f=new Farmer();
        f.setFarmerId(      pick(rs,"farmer_id","farmerId","id","uuid"));
        f.setFarmName(      pick(rs,"farm_name","farmName","name"));
        f.setImageF(        pick(rs,"image_f","imageF","image","avatar","profile_image","profileImage"));
        f.setSlipUrl(       pick(rs,"slip_url","slipUrl","qr_url","qrUrl","qr_path","qrPath"));
        f.setEmail(         pick(rs,"email","mail"));
        f.setAddress(       pick(rs,"address","addr"));
        f.setPassword(      pick(rs,"password","passwd"));
        f.setPhoneNumber(   pick(rs,"phone_number","phoneNumber","tel","mobile"));
        f.setRating(        pick(rs,"rating","rate"));
        f.setFarmLocation(  pick(rs,"farm_location","farmLocation","location","loc"));
        f.setStatus(        pick(rs,"status","state"));
        return f;
    }
    private String pick(ResultSet rs, String... names) throws SQLException {
        for (String n : names) { try { String v = rs.getString(n); if (v != null) return v; } catch (SQLException ignore){} }
        return null;
    }

    private String any(ResultSet rs, String... cols){
        for (String c : cols) try { String v = rs.getString(c); if (v != null) return v; } catch (Exception ignore){}
        return null;
    }
    private String str(Object o){ return o==null ? null : String.valueOf(o).trim(); }
    private String firstNonEmpty(String... arr){ if(arr==null) return null; for (String s: arr) if (StringUtils.hasText(s)) return s; return null; }
    private Object getField(Farmer f, String name){
        if (f==null) return null;
        try { return Farmer.class.getMethod("get"+Character.toUpperCase(name.charAt(0))+name.substring(1)).invoke(f); }
        catch (Exception ignore){ return null; }
    }
    private String getS(ResultSet rs,int i){ try{return rs.getString(i);}catch(Exception e){return null;} }
    private int getI(ResultSet rs,int i,int def){ try{int v=rs.getInt(i); return rs.wasNull()?def:v;}catch(Exception e){return def;} }
    private LocalDate getLD(ResultSet rs, int i){
        try{
            Date d = rs.getDate(i); // java.sql.Date
            return (d == null) ? null : d.toLocalDate();
        }catch(Exception e){ return null; }
    }
}
