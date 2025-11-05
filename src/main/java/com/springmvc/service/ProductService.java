// src/main/java/com/springmvc/service/ProductService.java
package com.springmvc.service;

import com.springmvc.model.HibernateConnection;
import com.springmvc.model.Product;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.Transaction;
import org.hibernate.query.Query;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ProductService {

    private final SessionFactory sessionFactory = HibernateConnection.getSessionFactory();

    /* ========================= พื้นฐานเดิม (แก้ getProduct ให้มี fallback) ========================= */

    public Product getProduct(String id) {
        if (id == null) return null;
        String key = id.trim();
        if (key.isEmpty()) return null;

        try (Session s = sessionFactory.openSession()) {
            // 1) ยิงด้วยคีย์หลักตามที่ entity map ไว้ก่อน (ไวสุด)
            Product p = s.get(Product.class, key);
            if (p != null) return p;

            // 2) เผื่อ mapping ไม่ได้ชี้ productId เป็น @Id → ค้นด้วย HQL ชี้ชัด productId
            try {
                Query<Product> q1 = s.createQuery(
                        "from Product p where p.productId = :x", Product.class);
                q1.setParameter("x", key);
                p = q1.uniqueResult();
                if (p != null) return p;
            } catch (Exception ignore) {}

            // 3) เผื่อบางข้อมูลใช้ฟิลด์ชื่อ id
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
        if (farmerId == null || farmerId.isBlank()) return java.util.List.of();
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

        // แสดงรายการที่พร้อมขาย/พรีออเดอร์ (ปรับตามธุรกิจได้)
        hql.append(" and (p.status is null or p.status = 'AVAILABLE' or p.status = 'พรีออเดอร์ได้แล้ว' or p.status='พร้อมส่ง') ");

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

        switch (safe(sort)) {
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

        hql.append(" and (p.status is null or p.status = 'AVAILABLE' or p.status='พรีออเดอร์ได้แล้ว' or p.status='พร้อมส่ง') ");

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
     * หา cover image ของสินค้า:
     * 1) ถ้ามี p.img ใช้เลย
     * 2) ถ้าไม่มีก็อ่านจาก product_image (รองรับชื่อคอลัมน์หลายแบบ)
     */
    public String findCoverImagePath(String productId) {
        if (!notBlank(productId)) return null;
        try (Session s = sessionFactory.openSession()) {
            Product p = s.get(Product.class, productId);
            if (p != null && notBlank(p.getImg())) return p.getImg();

            try {
                String cover = s.createNativeQuery(
                        "select MIN(imageUrl) from product_image where productId = :pid", String.class)
                        .setParameter("pid", productId)
                        .uniqueResult();
                if (notBlank(cover)) return cover;
            } catch (Exception ignore) {}

            try {
                String cover2 = s.createNativeQuery(
                        "select MIN(image_path) from product_image where product_id = :pid", String.class)
                        .setParameter("pid", productId)
                        .uniqueResult();
                if (notBlank(cover2)) return cover2;
            } catch (Exception ignore) {}

            return null;
        }
    }

    /* ====================== สำหรับหน้า “สินค้าของฉัน” ====================== */

    public List<Product> listMyProducts(String farmerId,
                                        String kw,
                                        String categoryId,
                                        BigDecimal minPrice,
                                        BigDecimal maxPrice,
                                        String sort,
                                        Integer page,
                                        Integer size) {

        if (!notBlank(farmerId)) return java.util.List.of();

        StringBuilder hql = new StringBuilder("from Product p where p.farmerId = :fid ");
        Map<String, Object> params = new HashMap<>();
        params.put("fid", farmerId);

        if (notBlank(kw)) {
            hql.append(" and (lower(p.productname) like :kw or lower(p.description) like :kw) ");
            params.put("kw", "%" + kw.trim().toLowerCase() + "%");
        }
        if (notBlank(categoryId)) {
            hql.append(" and p.categoryId = :cid ");
            params.put("cid", categoryId.trim());
        }
        if (minPrice != null) {
            hql.append(" and p.price >= :pmin ");
            params.put("pmin", minPrice);
        }
        if (maxPrice != null) {
            hql.append(" and p.price <= :pmax ");
            params.put("pmax", maxPrice);
        }

        switch (safe(sort)) {
            case "price_asc"  -> hql.append(" order by p.price asc, p.productname asc ");
            case "price_desc" -> hql.append(" order by p.price desc, p.productname asc ");
            case "name_asc"   -> hql.append(" order by p.productname asc ");
            case "name_desc"  -> hql.append(" order by p.productname desc ");
            default           -> hql.append(" order by p.productId desc ");
        }

        int pg = (page == null || page < 1) ? 1 : page;
        int sz = (size == null || size < 1) ? 24 : Math.min(size, 200);

        try (Session s = sessionFactory.openSession()) {
            Query<Product> q = s.createQuery(hql.toString(), Product.class);
            for (Map.Entry<String, Object> e : params.entrySet()) q.setParameter(e.getKey(), e.getValue());
            q.setFirstResult((pg - 1) * sz);
            q.setMaxResults(sz);
            return q.list();
        }
    }

    /* ============================== Utils ============================== */

    private static String safe(String s) { return (s == null) ? "" : s.trim().toLowerCase(); }
    private static boolean notBlank(String s){ return s != null && !s.trim().isEmpty(); }
}
