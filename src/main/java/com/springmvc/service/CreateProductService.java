package com.springmvc.service;

import com.springmvc.model.HibernateConnection;
import com.springmvc.model.Product;
import com.springmvc.model.ProductImage;
import org.hibernate.Session;
import org.hibernate.Transaction;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.file.*;
import java.sql.*;
import java.util.*;

@Service
public class CreateProductService {

    /** ต้องตรงกับ WebConfig:  /uploads/**  ->  file:///D:/Toos/png/ */
    private static final Path UPLOAD_ROOT = Paths.get("D:/Toos/png");

    // ชุดค่าสถานะที่ยอมรับ
    private static final Set<String> ALLOWED_STATUS = new HashSet<>(Arrays.asList(
            "พรีออเดอร์ได้แล้ว", "กำลังผลิต", "พร้อมสั่งซื้อแล้ว", "ปิดรับจอง"
    ));

    // map คำเก่า -> ค่ามาตรฐาน
    private static final Map<String, String> STATUS_ALIAS = new HashMap<>() {{
        put("กำลังเปิดรับจอง", "พรีออเดอร์ได้แล้ว");
        put("เปิดรับจอง",    "พรีออเดอร์ได้แล้ว");
        put("พรีออเดอร์",    "พรีออเดอร์ได้แล้ว");
        put("preorder",       "พรีออเดอร์ได้แล้ว");
        put("pre-order",      "พรีออเดอร์ได้แล้ว");

        put("พร้อมส่ง",       "พร้อมสั่งซื้อแล้ว");
        put("พร้อมจัดส่ง",     "พร้อมสั่งซื้อแล้ว");
        put("พร้อมซื้อ",       "พร้อมสั่งซื้อแล้ว");

        put("สินค้าหมดชั่วคราว", "ปิดรับจอง");
        put("หมด",              "ปิดรับจอง");
        put("out of stock",     "ปิดรับจอง");
        put("out-of-stock",     "ปิดรับจอง");
        put("outofstock",       "ปิดรับจอง");
        put("oos",              "ปิดรับจอง");
    }};

    /* ================= โหลดรูปของสินค้า ================= */
    public List<ProductImage> getImages(String productId) {
        final String sql = """
            SELECT imageId, productId, imageUrl, sortOrder
              FROM product_image
             WHERE productId=?
             ORDER BY sortOrder ASC, imageId ASC
        """;

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            return s.doReturningWork(conn -> {
                List<ProductImage> list = new ArrayList<>();
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, productId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            ProductImage pi = new ProductImage();
                            pi.setImageId(rs.getString("imageId"));
                            pi.setProductId(rs.getString("productId"));
                            pi.setImageUrl(rs.getString("imageUrl"));
                            pi.setSortOrder(rs.getInt("sortOrder"));
                            list.add(pi);
                        }
                    }
                }
                return list;
            });
        } catch (Exception e) {
            throw new RuntimeException("โหลดรูปสินค้าไม่สำเร็จ: " + e.getMessage(), e);
        }
    }

    /* ================= กติกาช่วยเหลือ ================= */

    /** true เมื่อสถานะหมายถึง "สั่งซื้อ/สั่งจองได้" */
    private static boolean isOpenStatus(String status) {
        return "พรีออเดอร์ได้แล้ว".equals(status) || "พร้อมสั่งซื้อแล้ว".equals(status);
    }

    /** บีบสถานะให้เหลือ 4 ค่ามาตรฐาน */
    private static String normalizeStatus(String s, boolean availabilityFallback) {
        String raw = (s == null ? "" : s.trim());
        if (raw.isEmpty()) return availabilityFallback ? "พรีออเดอร์ได้แล้ว" : "ปิดรับจอง";

        String key = raw.toLowerCase(Locale.ROOT);
        String mapped = STATUS_ALIAS.getOrDefault(key, raw);

        if (ALLOWED_STATUS.contains(mapped)) return mapped;
        return availabilityFallback ? "พรีออเดอร์ได้แล้ว" : "ปิดรับจอง";
    }

    /* ================= สร้างสินค้าใหม่ ================= */
    public void saveNew(Product product, List<MultipartFile> imageFiles, String farmerId) {
        ensureUploadFolder();

        // productId
        String productId = (product.getProductId() == null || product.getProductId().isBlank())
                ? UUID.randomUUID().toString()
                : product.getProductId();
        product.setProductId(productId);
        product.setFarmerId(farmerId);

        // ค่าพื้นฐาน
        int stockKg = Math.max(0, product.getStock());
        final BigDecimal price = safePrice(product.getPrice());

        // กติกาใหม่: availability มาจาก "status" (ไม่ผูกกับ stock)
        final String statusFinal = normalizeStatus(product.getStatus(), /*fallback*/ true);
        final boolean availabilityFinal = isOpenStatus(statusFinal);

        final String insertProduct = """
            INSERT INTO product
              (productId, productname, description, price, stock, categoryId,
               farmerId, availability, status)
            VALUES (?,?,?,?,?,?,?,?,?)
        """;

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();
            try {
                s.doWork(conn -> {
                    try (PreparedStatement ps = conn.prepareStatement(insertProduct)) {
                        ps.setString(1, productId);
                        ps.setString(2, safe(product.getProductname(), 100));
                        ps.setString(3, safe(product.getDescription(), 1000));
                        ps.setBigDecimal(4, price);
                        ps.setInt(5, stockKg);
                        ps.setString(6, product.getCategoryId());
                        ps.setString(7, product.getFarmerId());
                        ps.setBoolean(8, availabilityFinal);
                        ps.setString(9, statusFinal);
                        ps.executeUpdate();
                    }

                    String cover = saveImagesAndInsertRows(conn, productId, imageFiles);
                    if (cover != null) {
                        tryUpdateCoverImage(conn, productId, cover);
                    }
                });
                tx.commit();
            } catch (Exception e) {
                tx.rollback();
                throw e;
            }
        } catch (Exception e) {
            throw new RuntimeException("บันทึกสินค้าไม่สำเร็จ: " + e.getMessage(), e);
        }
    }

    /* ================= อัปเดตสินค้า ================= */
    public void update(Product product,
                       List<MultipartFile> newImages,
                       String farmerId,
                       String[] deleteImageIds) {

        ensureUploadFolder();

        String productId = product.getProductId();
        if (productId == null || productId.isBlank()) {
            throw new IllegalArgumentException("productId ว่าง: อัปเดตไม่ได้");
        }

        int stockKg = Math.max(0, product.getStock());
        final BigDecimal price = safePrice(product.getPrice());

        // กติกาใหม่เหมือน saveNew
        final String statusFinal = normalizeStatus(product.getStatus(), /*fallback*/ true);
        final boolean availabilityFinal = isOpenStatus(statusFinal);

        final String updateProduct = """
            UPDATE product
               SET productname=?, description=?, price=?, stock=?, categoryId=?,
                   availability=?, status=?
             WHERE productId=? AND farmerId=?
        """;

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();
            try {
                s.doWork(conn -> {
                    try (PreparedStatement ps = conn.prepareStatement(updateProduct)) {
                        ps.setString(1, safe(product.getProductname(), 100));
                        ps.setString(2, safe(product.getDescription(), 1000));
                        ps.setBigDecimal(3, price);
                        ps.setInt(4, stockKg);
                        ps.setString(5, product.getCategoryId());
                        ps.setBoolean(6, availabilityFinal);
                        ps.setString(7, statusFinal);
                        ps.setString(8, productId);
                        ps.setString(9, farmerId);
                        ps.executeUpdate();
                    }

                    // ลบรูปที่เลือก
                    if (deleteImageIds != null && deleteImageIds.length > 0) {
                        deleteImagesByIds(conn, productId, deleteImageIds);
                    }

                    // เพิ่มรูปใหม่ และอัปเดต cover ถ้าจำเป็น
                    String cover = saveImagesAndInsertRows(conn, productId, newImages);
                    if (cover != null) {
                        tryUpdateCoverImage(conn, productId, cover);
                    }
                });
                tx.commit();
            } catch (Exception e) {
                tx.rollback();
                throw e;
            }
        } catch (Exception e) {
            throw new RuntimeException("อัปเดตสินค้าไม่สำเร็จ: " + e.getMessage(), e);
        }
    }

    /* ================= ลบสินค้า (DB + ไฟล์รูป) ================= */
    public void deleteProduct(String productId, String farmerId) {
        if (isBlank(productId)) throw new IllegalArgumentException("productId ว่าง");

        final String getOwner = "SELECT farmerId, img FROM product WHERE productId=?";
        final String getImgs  = "SELECT imageUrl FROM product_image WHERE productId=?";
        final String delImgs  = "DELETE FROM product_image WHERE productId=?";
        final String delProd  = "DELETE FROM product WHERE productId=? AND farmerId=?";

        List<String> filesToDelete = new ArrayList<>();

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();
            try {
                s.doWork(conn -> {
                    String owner = null;
                    String cover = null;

                    // ตรวจสิทธิ์ + มีสินค้าจริงไหม
                    try (PreparedStatement ps = conn.prepareStatement(getOwner)) {
                        ps.setString(1, productId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                owner = rs.getString("farmerId");
                                cover = rs.getString("img");
                            }
                        }
                    }
                    if (owner == null) throw new RuntimeException("ไม่พบสินค้า");
                    if (!Objects.equals(owner, farmerId)) throw new RuntimeException("ไม่มีสิทธิ์ลบสินค้านี้");

                    // กันพลาดฝั่งเซิร์ฟเวอร์: มีอ้างอิงอยู่ห้ามลบ
                    Map<String, Long> ref = countReferencesForUi(productId, conn);
                    long per = ref.getOrDefault("perorder", 0L);
                    long pre = ref.getOrDefault("preorderdetail", 0L);
                    if (per + pre > 0) {
                        throw new RuntimeException(
                            "ลบสินค้าไม่ได้: มีคำสั่งซื้อ/พรีออเดอร์อ้างอิงอยู่ (perorder: " + per + ", preorderdetail: " + pre + ")"
                        );
                    }

                    // เตรียมไฟล์ที่จะลบจริงหลัง commit
                    try (PreparedStatement ps = conn.prepareStatement(getImgs)) {
                        ps.setString(1, productId);
                        try (ResultSet rs = ps.executeQuery()) {
                            while (rs.next()) {
                                String f = rs.getString("imageUrl");
                                if (f != null && !f.isEmpty()) filesToDelete.add(f);
                            }
                        }
                    }
                    if (cover != null && !cover.isEmpty()) filesToDelete.add(cover);

                    // ลบรูปใน DB
                    try (PreparedStatement ps = conn.prepareStatement(delImgs)) {
                        ps.setString(1, productId);
                        ps.executeUpdate();
                    }

                    // ลบสินค้า
                    int rows;
                    try (PreparedStatement ps = conn.prepareStatement(delProd)) {
                        ps.setString(1, productId);
                        ps.setString(2, farmerId);
                        rows = ps.executeUpdate();
                    }
                    if (rows == 0) throw new RuntimeException("ลบไม่สำเร็จ: ไม่พบสินค้าหรือไม่มีสิทธิ์");
                });
                tx.commit();
            } catch (Exception e) {
                tx.rollback();
                throw e;
            }
        } catch (Exception e) {
            throw new RuntimeException("ลบสินค้าไม่สำเร็จ: " + e.getMessage(), e);
        }

        // ลบไฟล์จริงหลัง commit (best-effort)
        Set<String> uniq = new HashSet<>(filesToDelete);
        for (String fn : uniq) {
            try { Files.deleteIfExists(UPLOAD_ROOT.resolve(fn)); } catch (Exception ignore) {}
        }
    }

    /** ใช้ให้ Controller แสดงผลบนหน้า JSP */
    public Map<String, Long> countReferencesForUi(String productId) {
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            return s.doReturningWork(conn -> countReferencesForUi(productId, conn));
        }
    }

    // ตัวเดียวกันแต่ reuse connection ภายในทรานแซคชัน
    private Map<String, Long> countReferencesForUi(String productId, Connection conn) {
        Map<String, Long> m = new HashMap<>();
        long per = 0, pre = 0;

        // ตารางที่โปรเจคนี้ใช้จริง
        per += tryCount(conn, "SELECT COUNT(*) FROM perorder WHERE productId=?", productId);
        pre += tryCount(conn, "SELECT COUNT(*) FROM preorderdetail WHERE productId=?", productId);

        // กันพลาด: schema ที่พบบ่อย
        per += tryCount(conn, "SELECT COUNT(*) FROM order_item WHERE productId=?", productId);
        per += tryCount(conn,
                "SELECT COUNT(*) FROM orders o JOIN order_item oi ON o.orderId=oi.orderId WHERE oi.productId=?",
                productId);

        m.put("perorder", per);
        m.put("preorderdetail", pre);
        return m;
    }

    /* ================= รูป/ไฟล์/เรคคอร์ด ================= */

    private String saveImagesAndInsertRows(Connection conn, String productId, List<MultipartFile> files) throws SQLException {
        if (files == null || files.isEmpty()) return null;

        final String insertImage = """
            INSERT INTO product_image (imageId, productId, imageUrl, sortOrder, createdAt)
            VALUES (?,?,?,?,?)
        """;
        String first = null;
        int sort = nextSortOrder(conn, productId);

        for (MultipartFile mf : files) {
            if (mf == null || mf.isEmpty()) continue;

            String original = Optional.ofNullable(mf.getOriginalFilename()).orElse("file");
            String ext = getExt(original);
            String filename = UUID.randomUUID() + ext;
            String imageId = UUID.randomUUID().toString();
            Path dest = UPLOAD_ROOT.resolve(filename);

            try {
                Files.copy(mf.getInputStream(), dest, StandardCopyOption.REPLACE_EXISTING);
            } catch (IOException e) {
                throw new RuntimeException("บันทึกรูปไม่สำเร็จ: " + original, e);
            }

            try (PreparedStatement ps = conn.prepareStatement(insertImage)) {
                ps.setString(1, imageId);
                ps.setString(2, productId);
                ps.setString(3, filename);
                ps.setInt(4, sort++);
                ps.setTimestamp(5, new Timestamp(System.currentTimeMillis()));
                ps.executeUpdate();
            } catch (SQLException e) {
                try { Files.deleteIfExists(dest); } catch (IOException ignore) {}
                throw e;
            }

            if (first == null) first = filename;
        }
        return first;
    }

    private void deleteImagesByIds(Connection conn, String productId, String[] ids) throws SQLException {
        final String q = "SELECT imageUrl FROM product_image WHERE imageId=? AND productId=?";
        final String d = "DELETE FROM product_image WHERE imageId=? AND ProductId=?";

        for (String id : ids) {
            if (isBlank(id)) continue;

            String url = null;
            try (PreparedStatement ps = conn.prepareStatement(q)) {
                ps.setString(1, id);
                ps.setString(2, productId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) url = rs.getString("imageUrl");
                }
            }

            if (url != null) {
                try { Files.deleteIfExists(UPLOAD_ROOT.resolve(url)); } catch (IOException ignore) {}
            }

            try (PreparedStatement ps = conn.prepareStatement(d)) {
                ps.setString(1, id);
                ps.setString(2, productId);
                ps.executeUpdate();
            }
        }
    }

    private void tryUpdateCoverImage(Connection conn, String productId, String filename) throws SQLException {
        final String upd = "UPDATE product SET img=? WHERE productId=?";
        try (PreparedStatement ps = conn.prepareStatement(upd)) {
            ps.setString(1, filename);
            ps.setString(2, productId);
            ps.executeUpdate();
        } catch (SQLException ignore) { /* ถ้าไม่มีคอลัมน์ img ก็ข้ามได้ */ }
    }

    private int nextSortOrder(Connection conn, String productId) {
        final String sql = "SELECT MAX(sortOrder) FROM product_image WHERE productId=?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int max = rs.getInt(1);
                    return rs.wasNull() ? 0 : max + 1;
                }
            }
        } catch (SQLException ignore) {}
        return 0;
    }

    /* ================= Helpers ================= */

    private void ensureUploadFolder() {
        try { Files.createDirectories(UPLOAD_ROOT); } catch (IOException ignored) {}
    }

    private static boolean isBlank(String s) { return s == null || s.trim().isEmpty(); }

    private static String safe(String s, int max) {
        if (s == null) return null;
        String t = s.trim();
        return t.length() <= max ? t : t.substring(0, max);
    }

    /** ราคาเงิน: 2 ตำแหน่ง, ไม่ติดลบ, เพดานเบื้องต้น */
    private static BigDecimal safePrice(BigDecimal p) {
        if (p == null) return new BigDecimal("0");
        if (p.compareTo(BigDecimal.ZERO) < 0) p = BigDecimal.ZERO;
        if (p.compareTo(new BigDecimal("9999999")) > 0) p = new BigDecimal("9999999");
        return p.setScale(2, RoundingMode.HALF_UP);
    }

    private static boolean parseBool(Object v) {
        if (v == null) return false;
        String s = String.valueOf(v).trim().toLowerCase(Locale.ROOT);
        return "true".equals(s) || "1".equals(s) || "on".equals(s) || "yes".equals(s);
    }

    // === helper: คืนค่านามสกุลไฟล์ (รวมจุด) เช่น ".png", ถ้าไม่มีให้คืน "" ===
    private static String getExt(String name) {
        if (name == null) return "";
        int i = name.lastIndexOf('.');
        return (i >= 0 && i < name.length() - 1)
                ? name.substring(i).toLowerCase(Locale.ROOT)
                : "";
    }

    // === helper: นับแถวแบบเงียบ ๆ ถ้าตาราง/คอลัมน์ไม่มีให้คืน 0 (ไม่ throw) ===
    private long tryCount(Connection conn, String sql, String productId) {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getLong(1);
            }
        } catch (SQLException ignore) { /* ไม่มีตาราง/คอลัมน์ก็ข้ามได้ */ }
        return 0;
    }
}
