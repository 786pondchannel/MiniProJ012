package com.springmvc.service;

import com.springmvc.model.HibernateConnection;
import org.hibernate.Session;
import org.hibernate.Transaction;
import org.hibernate.query.NativeQuery;
import org.hibernate.exception.SQLGrammarException;

import java.util.*;

public class ReviewService {

    /* ===== ช่วยเช็คสเต็ป ===== */
    private static boolean isStep3or4(String orderStatus, String paymentStatus) {
        if (orderStatus == null || paymentStatus == null) return false;
        String os = orderStatus.trim().toUpperCase(Locale.ROOT);
        String ps = paymentStatus.trim().toUpperCase(Locale.ROOT);

        boolean orderOk = os.equals("FARMER_CONFIRMED")
                || os.equals("PREPARING_SHIPMENT")
                || os.equals("SHIPPED")
                || os.equals("COMPLETED");

        boolean payOk = ps.equals("PAID_PENDING_VERIFY") || ps.equals("PAID_CONFIRMED");
        return orderOk && payOk;
    }

    /* ===== ตรวจว่า exception เป็น grammar ที่ควรลอง fallback ต่อไหม ===== */
    private static boolean isGrammarLike(Throwable t) {
        Throwable c = t;
        while (c.getCause() != null) c = c.getCause();
        String msg = (c.getMessage() == null ? "" : c.getMessage()).toLowerCase(Locale.ROOT);
        return (t instanceof SQLGrammarException)
                || msg.contains("unknown column")
                || msg.contains("doesn't exist")
                || msg.contains("exist")
                || msg.contains("syntax");
    }

    /* ===== ดึงสถานะ order + payment พร้อม fallback หลายแบบ ===== */
    private Object[] fetchOrderStatusRow(String orderId, String memberId) {
        String[][] attempts = new String[][]{
                {"preorder", "paymentStatus"},
                {"preorder", "paymEntStatus"},
                {"perorder", "paymentStatus"},     // กันเหนียวตาม ERD เก่า
                {"perorder", "paymEntStatus"}
        };

        for (String[] at : attempts) {
            String table = at[0];
            String payCol = at[1];
            String sql = "SELECT orderStatus, " + payCol + " FROM " + table +
                         " WHERE orderId=:oid AND memberId=:mid";
            try (Session s = HibernateConnection.getSessionFactory().openSession()) {
                Object result = s.createNativeQuery(sql)
                        .setParameter("oid", orderId)
                        .setParameter("mid", memberId)
                        .uniqueResult();
                if (result == null) return null;  // ไม่มีแถว (order ไม่ใช่ของคนนี้)
                return (Object[]) result;
            } catch (Exception e) {
                if (isGrammarLike(e)) {
                    // ลองตัวเลือกถัดไป
                    continue;
                }
                // อื่น ๆ โยนต่อ
                throw new RuntimeException(e);
            }
        }
        // ทุกตัวเลือกพัง = โครงสร้าง DB ไม่ตรงสักแบบ
        throw new RuntimeException("ไม่พบคอลัมน์ paymentStatus/paymEntStatus หรือชื่อตาราง preorder/perorder ไม่ตรงกับฐานข้อมูล");
    }

    /* ===== สิทธิ์รีวิว ===== */
    public boolean canBuyerReviewOrder(String orderId, String memberId) {
        if (orderId == null || memberId == null) return false;
        try {
            Object[] row = fetchOrderStatusRow(orderId, memberId);
            if (row == null) return false;
            String orderStatus = row[0] == null ? null : row[0].toString();
            String payStatus   = row[1] == null ? null : row[1].toString();
            return isStep3or4(orderStatus, payStatus);
        } catch (Exception e) {
            throw new RuntimeException("ตรวจสอบสิทธิ์รีวิวล้มเหลว: " + e.getMessage(), e);
        }
    }

    /* ===== เคยรีวิวใบเสร็จนี้หรือยัง ===== */
    public boolean hasReviewedThisOrder(String orderId, String memberId) {
        final String sql = "SELECT COUNT(*) FROM review WHERE orderId=:oid AND memberId=:mid";
        try (Session session = HibernateConnection.getSessionFactory().openSession()) {
            Number n = (Number) session.createNativeQuery(sql)
                    .setParameter("oid", orderId)
                    .setParameter("mid", memberId)
                    .uniqueResult();
            return n != null && n.longValue() > 0;
        } catch (Exception e) {
            throw new RuntimeException("ตรวจสอบประวัติรีวิวล้มเหลว: " + e.getMessage(), e);
        }
    }

    /* ===== ดึงสินค้าในออเดอร์ (สำหรับโชว์ในฟอร์ม) ===== */
    public List<Map<String, Object>> getOrderProducts(String orderId) {
        final String sql =
                "SELECT d.productId, p.productname, p.img, d.quantity " +
                "FROM preorderdetail d " +
                "JOIN product p ON p.productId = d.productId " +
                "WHERE d.orderId = :oid " +
                "ORDER BY d.productId ASC";

        try (Session session = HibernateConnection.getSessionFactory().openSession()) {
            @SuppressWarnings("unchecked")
            List<Object[]> rows = session.createNativeQuery(sql)
                    .setParameter("oid", orderId)
                    .list();

            List<Map<String, Object>> list = new ArrayList<>();
            for (Object[] r : rows) {
                Map<String, Object> m = new HashMap<>();
                m.put("productId",   r[0] == null ? null : r[0].toString());
                m.put("productname", r[1] == null ? null : r[1].toString());
                m.put("img",         r[2] == null ? null : r[2].toString());
                m.put("quantity",    r[3] == null ? 0 : ((Number) r[3]).intValue());
                list.add(m);
            }
            return list;
        } catch (Exception e) {
            throw new RuntimeException("ดึงสินค้าในออเดอร์ล้มเหลว: " + e.getMessage(), e);
        }
    }

    /* ===== บันทึกรีวิว (1 รีวิว/ใบเสร็จ, ผูกสินค้าตัวแรก) ===== */
    public String createReviewForOrder(String orderId, String memberId, int rating, String comment) {
        if (rating < 1 || rating > 5) throw new IllegalArgumentException("ให้คะแนน 1–5 เท่านั้น");
        if (!canBuyerReviewOrder(orderId, memberId)) {
            throw new IllegalStateException("รีวิวได้เฉพาะออเดอร์ขั้นที่ 3 หรือ 4 และต้องเป็นเจ้าของออเดอร์");
        }
        if (hasReviewedThisOrder(orderId, memberId)) {
            throw new IllegalStateException("คุณได้รีวิวใบเสร็จนี้ไปแล้ว");
        }

        List<Map<String, Object>> items = getOrderProducts(orderId);
        if (items.isEmpty()) throw new IllegalStateException("ไม่พบสินค้าในออเดอร์นี้");
        String productId = String.valueOf(items.get(0).get("productId"));

        String reviewId = java.util.UUID.randomUUID().toString();
        final String sql =
                "INSERT INTO review (reviewId, rating, comment, reviewDate, memberId, productId, orderId) " +
                "VALUES (:rid, :rating, :comment, CURRENT_DATE, :mid, :pid, :oid)";

        Transaction tx = null;
        try (Session session = HibernateConnection.getSessionFactory().openSession()) {
            tx = session.beginTransaction();

            NativeQuery<?> q = session.createNativeQuery(sql)
                    .setParameter("rid", reviewId)
                    .setParameter("rating", rating)
                    .setParameter("comment", (comment == null || comment.isBlank()) ? null : comment.trim())
                    .setParameter("mid", memberId)
                    .setParameter("pid", productId)
                    .setParameter("oid", orderId);

            q.executeUpdate();
            tx.commit();
            return reviewId;
        } catch (Exception e) {
            if (tx != null) tx.rollback();
            throw new RuntimeException("บันทึกรีวิวล้มเหลว: " + e.getMessage(), e);
        }
    }

    /* ===== สรุปรีวิวสินค้า (optional) ===== */
    public Map<String, Object> getProductReviewSummary(String productId) {
        final String sql = "SELECT COUNT(*) AS cnt, IFNULL(AVG(rating),0) AS avgRating FROM review WHERE productId=:pid";
        try (Session session = HibernateConnection.getSessionFactory().openSession()) {
            Object[] row = (Object[]) session.createNativeQuery(sql)
                    .setParameter("pid", productId)
                    .uniqueResult();

            Map<String, Object> m = new HashMap<>();
            if (row != null) {
                m.put("count", ((Number) row[0]).intValue());
                m.put("avgRating", ((Number) row[1]).doubleValue());
            } else {
                m.put("count", 0);
                m.put("avgRating", 0.0);
            }
            return m;
        } catch (Exception e) {
            throw new RuntimeException("สรุปรีวิวล้มเหลว: " + e.getMessage(), e);
        }
    }
}
