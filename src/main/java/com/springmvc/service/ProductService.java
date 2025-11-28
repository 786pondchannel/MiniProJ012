package com.springmvc.service;

import com.springmvc.model.HibernateConnection;
import com.springmvc.model.Product;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.Transaction;
import org.hibernate.query.Query;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.nio.file.*;
import java.util.*;

@Service
public class ProductService {

    private final SessionFactory sessionFactory = HibernateConnection.getSessionFactory();

    /* ========================= พื้นฐานเดิม (คงโครงเดิมไว้) ========================= */

    public Product getProduct(String id) {
        if (id == null) return null;
        String key = id.trim();
        if (key.isEmpty()) return null;

        try (Session s = sessionFactory.openSession()) {
            // by PK
            Product p = s.get(Product.class, key);
            if (p != null) return p;

            // by productId field
            try {
                Query<Product> q1 = s.createQuery(
                        "from Product p where p.productId = :x", Product.class);
                q1.setParameter("x", key);
                p = q1.uniqueResult();
                if (p != null) return p;
            } catch (Exception ignore) {}

            // เผื่อมี field id ใน model เก่าๆ
            try {
                Query<Product> q2 = s.createQuery(
                        "from Product p where p.id = :x", Product.class);
                q2.setParameter("x", key);
                return q2.uniqueResult();
            } catch (Exception ignore) {}

            return null;
        }
    }

    public List<Product> getProductsByFarmer(String farmerId) {
        if (farmerId == null || farmerId.isBlank()) return List.of();
        try (Session s = sessionFactory.openSession()) {
            return s.createQuery(
                    "from Product p where p.farmerId = :fid order by p.productId desc",
                    Product.class
            ).setParameter("fid", farmerId).list();
        }
    }

    public void createProductWithoutImage(Product p) {
        try (Session s = sessionFactory.openSession()) {
            Transaction tx = s.beginTransaction();
            s.save(p);
            tx.commit();
        }
    }

    public void updateProductWithoutImage(Product p) {
        try (Session s = sessionFactory.openSession()) {
            Transaction tx = s.beginTransaction();
            s.update(p);
            tx.commit();
        }
    }

    /* ========== สร้าง/แก้สินค้า + จัดการไฟล์รูป (ใช้คอลัมน์ img เดิม) ========== */

    /** สร้างสินค้าใหม่ พร้อมอัปโหลดรูป (ถ้ามี) */
    public void createProductWithImage(Product p, InputStream imageStream, String originalFilename) {
        if (imageStream != null && originalFilename != null && !originalFilename.isBlank()) {
            String storedName = saveProductImage(imageStream, originalFilename);
            p.setImg(storedName);  // เก็บชื่อไฟล์ลง product.img
        }
        createProductWithoutImage(p);
    }

    /** อัปเดตสินค้า และถ้ามีไฟล์ใหม่ ให้แทนที่ (ลบไฟล์เก่าถ้าจำเป็น) */
    public void updateProductWithImage(Product p, InputStream imageStream, String originalFilename, boolean replaceImage) {
        try (Session s = sessionFactory.openSession()) {
            Transaction tx = s.beginTransaction();

            Product existing = s.get(Product.class, p.getProductId());
            String oldStored = (existing != null) ? safe(existing.getImg()) : null;

            s.merge(p);

            if (imageStream != null && originalFilename != null && !originalFilename.isBlank()) {
                String newStored = saveProductImage(imageStream, originalFilename);
                p.setImg(newStored);
                s.merge(p);

                if (replaceImage && notBlank(oldStored) && !looksLikeUrlPath(oldStored)) {
                    safeDeleteStoredImage(oldStored);
                }
            }

            tx.commit();
        }
    }

    /* ===================== ค้นหารายการสาธารณะ (Catalog) ===================== */

    public List<Product> searchPublicProducts(String kw,
                                              String categoryId,
                                              BigDecimal minPrice,
                                              BigDecimal maxPrice,
                                              String sort,
                                              int page,
                                              int size) {
        StringBuilder hql = new StringBuilder("from Product p where 1=1 ");
        Map<String, Object> params = new HashMap<>();

        // สถานะที่ถือว่า "เปิดขาย/เปิดจอง"
        hql.append(" and (p.status is null or p.status = 'พรีออเดอร์ได้แล้ว' or p.status = 'พร้อมสั่งซื้อแล้ว') ");

        if (notBlank(kw)) {
            hql.append(" and (lower(p.productname) like :kw or lower(p.description) like :kw) ");
            params.put("kw", "%" + kw.trim().toLowerCase() + "%");
        }
        if (notBlank(categoryId)) {
            hql.append(" and p.categoryId = :cid ");
            params.put("cid", categoryId);
        }
        if (minPrice != null) {
            hql.append(" and p.price >= :pmin ");
            params.put("pmin", minPrice);
        }
        if (maxPrice != null) {
            hql.append(" and p.price <= :pmax ");
            params.put("pmax", maxPrice);
        }

        switch (safe(sort).toLowerCase()) {
            case "price-asc"  -> hql.append(" order by p.price asc, p.productname asc ");
            case "price-desc" -> hql.append(" order by p.price desc, p.productname asc ");
            case "name-asc"   -> hql.append(" order by p.productname asc ");
            case "name-desc"  -> hql.append(" order by p.productname desc ");
            default           -> hql.append(" order by p.productId desc ");
        }

        int pg = Math.max(page, 1);
        int sz = Math.max(Math.min(size, 200), 12);

        try (Session s = sessionFactory.openSession()) {
            Query<Product> q = s.createQuery(hql.toString(), Product.class);
            for (Map.Entry<String, Object> e : params.entrySet()) q.setParameter(e.getKey(), e.getValue());
            q.setFirstResult((pg - 1) * sz);
            q.setMaxResults(sz);
            return q.list();
        }
    }

    public long countPublicProducts(String kw,
                                    String categoryId,
                                    BigDecimal minPrice,
                                    BigDecimal maxPrice) {
        StringBuilder hql = new StringBuilder("select count(p.productId) from Product p where 1=1 ");
        Map<String, Object> params = new HashMap<>();

        hql.append(" and (p.status is null or p.status = 'พรีออเดอร์ได้แล้ว' or p.status = 'พร้อมสั่งซื้อแล้ว') ");

        if (notBlank(kw)) {
            hql.append(" and (lower(p.productname) like :kw or lower(p.description) like :kw) ");
            params.put("kw", "%" + kw.trim().toLowerCase() + "%");
        }
        if (notBlank(categoryId)) {
            hql.append(" and p.categoryId = :cid ");
            params.put("cid", categoryId);
        }
        if (minPrice != null) {
            hql.append(" and p.price >= :pmin ");
            params.put("pmin", minPrice);
        }
        if (maxPrice != null) {
            hql.append(" and p.price <= :pmax ");
            params.put("pmax", maxPrice);
        }

        try (Session s = sessionFactory.openSession()) {
            Query<Long> q = s.createQuery(hql.toString(), Long.class);
            for (Map.Entry<String, Object> e : params.entrySet()) q.setParameter(e.getKey(), e.getValue());
            Long cnt = q.uniqueResult();
            return (cnt == null) ? 0L : cnt;
        }
    }

    /**
     * หา cover:
     * - ถ้า product.img มีค่า → แปลงเป็น URL
     * - ถ้าไม่มี → ใช้ตัวแรกจาก product_image.imageUrl
     */
    public String findCoverImagePath(String productId) {
        if (!notBlank(productId)) return null;
        try (Session s = sessionFactory.openSession()) {
            Product p = s.get(Product.class, productId);
            if (p != null && notBlank(p.getImg())) {
                return toPublicUrl(p.getImg());
            }
            try {
                String cover = s.createNativeQuery(
                        "select MIN(imageUrl) from product_image where productId = :pid", String.class)
                        .setParameter("pid", productId)
                        .uniqueResult();
                if (notBlank(cover)) return toPublicUrl(cover);
            } catch (Exception ignore) {}
            return null;
        }
    }

    /* ============================== Utils ============================== */

    private static String safe(String s) { return (s == null) ? "" : s.trim(); }
    private static boolean notBlank(String s){ return s != null && !s.trim().isEmpty(); }

    /* ========================== อัปโหลดรูป (ไม่เพิ่มไฟล์ใหม่) ========================== */

    /** root เก็บไฟล์อัปโหลด: ใน Docker = /app/uploads (แมปกับ ./uploads) */
    private Path uploadRoot() {
        String root = System.getenv("UPLOAD_DIR");
        if (root == null || root.isBlank()) root = "/app/uploads";
        return Paths.get(root).toAbsolutePath().normalize();
    }

    /** โฟลเดอร์สำหรับรูปสินค้า */
    private Path productUploadDir() {
        Path dir = uploadRoot().resolve("products");
        try {
            Files.createDirectories(dir);
        } catch (IOException e) {
            throw new RuntimeException("Cannot create upload dir: " + dir, e);
        }
        return dir;
    }

    /** บันทึกรูปลงดิสก์และคืน “ชื่อไฟล์ที่เก็บจริง” (เก็บลง product.img) */
    private String saveProductImage(InputStream in, String originalFilename) {
        try {
            String ext = getExtensionSafe(originalFilename);
            String newName = UUID.randomUUID().toString() + (ext.isEmpty() ? "" : "." + ext);

            Path dir = productUploadDir();
            Path target = dir.resolve(newName).normalize();
            if (!target.startsWith(dir)) throw new IllegalArgumentException("Invalid file path");

            Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
            return newName;
        } catch (IOException e) {
            throw new RuntimeException("Cannot store file", e);
        }
    }

    /** ลบไฟล์เก่าแบบปลอดภัย (รับเป็นชื่อไฟล์ที่เราเคยเซฟเอง) */
    private void safeDeleteStoredImage(String storedName) {
        try {
            Path dir = productUploadDir();
            Path target = dir.resolve(storedName).normalize();
            if (target.startsWith(dir) && Files.exists(target)) {
                Files.deleteIfExists(target);
            }
        } catch (Exception ignored) {}
    }

    /** ตีความนามสกุลแบบปลอดภัย */
    private static String getExtensionSafe(String name) {
        if (name == null) return "";
        int dot = name.lastIndexOf('.');
        if (dot < 0 || dot == name.length() - 1) return "";
        String ext = name.substring(dot + 1).toLowerCase(Locale.ROOT);
        return ext.replaceAll("[^a-z0-9]+", "");
        }

    /** true ถ้า value ดูเป็น path/URL อยู่แล้ว (ขึ้นต้น /, http://, https://) */
    private static boolean looksLikeUrlPath(String s) {
        String x = safe(s).toLowerCase(Locale.ROOT);
        return x.startsWith("/") || x.startsWith("http://") || x.startsWith("https://");
    }

    /** แปลงค่าที่เก็บใน DB ให้เป็น URL ที่เสิร์ฟได้จริง */
    private static String toPublicUrl(String stored) {
        if (!notBlank(stored)) return null;
        if (looksLikeUrlPath(stored)) return stored;
        return "/uploads/products/" + stored.trim();
    }
}
