package com.springmvc.service;

import com.springmvc.model.HibernateConnection;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.Transaction;
import org.hibernate.query.NativeQuery;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
public class FarmerOrdersService {

    private final SessionFactory sf = HibernateConnection.getSessionFactory();

    // ===== Wire OrderService เพื่อตัดสต๊อก “กิโล” ตอนยืนยันชำระเงิน =====
    @Autowired
    private OrderService orderService;

    // ====== ค่าคงที่สถานะ ======
    public static final String ST_SENT_TO_FARMER     = "SENT_TO_FARMER";
    public static final String ST_FARMER_CONFIRMED   = "FARMER_CONFIRMED";
    public static final String ST_PREPARING_SHIPMENT = "PREPARING_SHIPMENT";
    public static final String ST_SHIPPED            = "SHIPPED";
    public static final String ST_COMPLETED          = "COMPLETED";
    public static final String ST_REJECTED           = "REJECTED";
    public static final String ST_CANCELED           = "CANCELED";

    public static final String PAY_UNPAID            = "UNPAID";
    public static final String PAY_AWAIT_BUYER       = "AWAITING_BUYER_PAYMENT";
    public static final String PAY_PAID_PENDING      = "PAID_PENDING_VERIFY";
    public static final String PAY_PAID_CONFIRMED    = "PAID_CONFIRMED";
    public static final String PAY_REFUNDED          = "REFUNDED";

    /** รายการออเดอร์ของร้าน */
    @SuppressWarnings("unchecked")
    public List<Object[]> listOrders(String farmerId, String q, String orderStatus, String paymentStatus) {
        try (Session s = sf.openSession()) {
            StringBuilder sql = new StringBuilder("""
                SELECT o.orderId, o.orderDate, o.totalPrice, o.orderStatus, o.paymentStatus,
                       m.Fullname AS customerName
                  FROM perorder o
                  LEFT JOIN member m ON m.memberId = o.memberId
                 WHERE o.farmerId = :fid
            """);
            if (q != null && !q.isBlank())                         sql.append(" AND (o.orderId LIKE :q) ");
            if (orderStatus != null && !orderStatus.isBlank())     sql.append(" AND o.orderStatus = :ost ");
            if (paymentStatus != null && !paymentStatus.isBlank()) sql.append(" AND o.paymentStatus = :pst ");
            sql.append(" ORDER BY o.orderDate DESC ");

            NativeQuery<Object[]> nq = s.createNativeQuery(sql.toString());
            nq.setParameter("fid", farmerId);
            if (q != null && !q.isBlank())                         nq.setParameter("q", "%" + q + "%");
            if (orderStatus != null && !orderStatus.isBlank())     nq.setParameter("ost", orderStatus);
            if (paymentStatus != null && !paymentStatus.isBlank()) nq.setParameter("pst", paymentStatus);
            return nq.list();
        }
    }

    /** Header ออเดอร์ */
    public OrderHeader getOrderHeader(String farmerId, String orderId) {
        try (Session s = sf.openSession()) {
            Object[] row = (Object[]) s.createNativeQuery("""
                SELECT o.orderId, o.orderDate, o.totalPrice, o.orderStatus, o.paymentStatus,
                       o.memberId, o.farmerId, o.DeliveryDate,
                       m.Fullname, m.PhoneNumber, m.Address, m.email
                  FROM perorder o
                  LEFT JOIN member m ON m.memberId = o.memberId
                 WHERE o.orderId = :oid AND o.farmerId = :fid
            """)
            .setParameter("oid", orderId)
            .setParameter("fid", farmerId)
            .uniqueResult();

            if (row == null) return null;

            int i = 0;
            OrderHeader h = new OrderHeader();
            h.orderId       = (String) row[i++];
            Date od         = (Date) row[i++];
            h.orderDate     = (od == null) ? null : new java.util.Date(od.getTime());
            h.totalPrice    = (BigDecimal) row[i++];
            h.orderStatus   = (String) row[i++];
            h.paymentStatus = (String) row[i++];
            h.memberId      = (String) row[i++];
            h.farmerId      = (String) row[i++];
            h.deliveryDate  = (String) row[i++];
            h.customerName  = (String) row[i++];
            h.customerPhone = (String) row[i++];
            h.customerAddr  = (String) row[i++];
            h.customerEmail = (String) row[i++];
            return h;
        }
    }

    /** รายการสินค้าในออเดอร์ */
    @SuppressWarnings("unchecked")
    public List<OrderItem> getOrderItems(String farmerId, String orderId) {
        try (Session s = sf.openSession()) {
            List<Object[]> rows = s.createNativeQuery("""
                SELECT d.preOrderId,
                       d.productId,
                       p.Productname,
                       p.Img,
                       p.price,
                       d.quantity,
                       (p.price * d.quantity) AS lineTotal,
                       d.preOrderStatus
                  FROM preorderdetail d
                  JOIN product p  ON p.productId = d.productId
                  JOIN perorder o ON o.orderId   = d.orderId
                 WHERE d.orderId  = :oid
                   AND o.farmerId = :fid
                 ORDER BY p.Productname ASC
            """)
            .setParameter("oid", orderId)
            .setParameter("fid", farmerId)
            .list();

            List<OrderItem> list = new ArrayList<>();
            for (Object[] r : rows) {
                int i = 0;
                OrderItem it = new OrderItem();
                it.preOrderId     = (String) r[i++];
                it.productId      = (String) r[i++];
                it.productName    = (String) r[i++];
                it.img            = (String) r[i++];
                it.price          = (BigDecimal) r[i++];
                it.qty            = ((Number) r[i++]).intValue();
                it.lineTotal      = (BigDecimal) r[i++];
                it.preOrderStatus = (String) r[i++];
                list.add(it);
            }
            return list;
        }
    }

    /** หลักฐานการชำระเงิน */
    @SuppressWarnings("unchecked")
    public List<ReceiptInfo> getReceipts(String farmerId, String orderId) {
        try (Session s = sf.openSession()) {
            Long owned = ((Number) s.createNativeQuery(
                "SELECT COUNT(*) FROM perorder WHERE orderId=:oid AND farmerId=:fid"
            ).setParameter("oid", orderId)
             .setParameter("fid", farmerId)
             .uniqueResult()).longValue();
            if (owned == 0) return List.of();

            List<Object[]> rows = s.createNativeQuery("""
                SELECT receiptId, ReferenceID, Img
                  FROM receipt
                 WHERE perorder_orderId = :oid
                 ORDER BY receiptId DESC
            """)
            .setParameter("oid", orderId)
            .list();

            List<ReceiptInfo> list = new ArrayList<>();
            for (Object[] r : rows) {
                ReceiptInfo ri = new ReceiptInfo();
                ri.receiptId   = (String) r[0];
                ri.referenceId = (String) r[1];
                ri.img         = (String) r[2];
                list.add(ri);
            }
            return list;
        }
    }

    // ====== Actions ======

    /** ร้านกดยืนยันคำสั่งซื้อ → เปิดให้ลูกค้าชำระ */
    public boolean confirmOrder(String farmerId, String orderId) {
        try (Session s = sf.openSession()) {
            Transaction tx = s.beginTransaction();
            int updated = s.createNativeQuery("""
                UPDATE perorder
                   SET orderStatus = :st, paymentStatus = :pay
                 WHERE orderId    = :oid AND farmerId = :fid AND orderStatus = :curr
            """)
            .setParameter("st",  ST_FARMER_CONFIRMED)
            .setParameter("pay", PAY_AWAIT_BUYER)
            .setParameter("oid", orderId)
            .setParameter("fid", farmerId)
            .setParameter("curr", ST_SENT_TO_FARMER)
            .executeUpdate();
            tx.commit();
            return updated > 0;
        }
    }

    /** ปฏิเสธคำสั่งซื้อ */
    public boolean rejectOrder(String farmerId, String orderId) {
        try (Session s = sf.openSession()) {
            Transaction tx = s.beginTransaction();
            int updated = s.createNativeQuery("""
                UPDATE perorder
                   SET orderStatus = :st
                 WHERE orderId    = :oid
                   AND farmerId    = :fid
                   AND orderStatus IN (:a, :b)
            """)
            .setParameter("st", ST_REJECTED)
            .setParameter("oid", orderId)
            .setParameter("fid", farmerId)
            .setParameter("a", ST_SENT_TO_FARMER)
            .setParameter("b", ST_FARMER_CONFIRMED)
            .executeUpdate();
            tx.commit();
            return updated > 0;
        }
    }

    /** ปฏิเสธ (มีเหตุผล) — เก็บรูปแบบเดิมไว้ */
    public boolean rejectOrder(String farmerId, String orderId, String reason) {
        return rejectOrder(farmerId, orderId);
    }

    /**
     * ร้าน “ยืนยันรับชำระเงิน”
     * เปลี่ยนมาเรียก OrderService.farmerVerifyPayment(orderId, farmerId)
     * เพื่ออัปเดตสถานะ + ตัดสต๊อกเป็นกิโล (อ่านจาก preorderdetail.quantityKg หรือ fallback quantity)
     */
    public boolean verifyPayment(String farmerId, String orderId) {
        // ให้ OrderService จัดการทั้งหมดในทรานแซคชันเดียว (รวมตัดสต๊อกกิโล)
        orderService.farmerVerifyPayment(orderId, farmerId);
        return true;
    }

    /** เริ่มเตรียมจัดส่ง */
    public boolean startPrepare(String farmerId, String orderId) {
        try (Session s = sf.openSession()) {
            Transaction tx = s.beginTransaction();
            int updated = s.createNativeQuery("""
                UPDATE perorder
                   SET orderStatus = :st
                 WHERE orderId    = :oid
                   AND farmerId    = :fid
                   AND orderStatus = :curr
            """)
            .setParameter("st", ST_PREPARING_SHIPMENT)
            .setParameter("oid", orderId)
            .setParameter("fid", farmerId)
            .setParameter("curr", ST_FARMER_CONFIRMED)
            .executeUpdate();
            tx.commit();
            return updated > 0;
        }
    }

    /** จัดส่งแล้ว (กำหนดวันที่จัดส่งได้) */
    public boolean markShipped(String farmerId, String orderId, String deliveryDate) {
        try (Session s = sf.openSession()) {
            if (deliveryDate == null || deliveryDate.isBlank()) {
                deliveryDate = Date.valueOf(LocalDate.now()).toString();
            }
            Transaction tx = s.beginTransaction();
            int updated = s.createNativeQuery("""
                UPDATE perorder
                   SET orderStatus = :st,
                       DeliveryDate = :dd
                 WHERE orderId    = :oid
                   AND farmerId    = :fid
                   AND orderStatus IN (:a,:b)
            """)
            .setParameter("st", ST_SHIPPED)
            .setParameter("dd", deliveryDate)
            .setParameter("oid", orderId)
            .setParameter("fid", farmerId)
            .setParameter("a", ST_FARMER_CONFIRMED)
            .setParameter("b", ST_PREPARING_SHIPMENT)
            .executeUpdate();
            tx.commit();
            return updated > 0;
        }
    }

    /** ปิดงาน (สำเร็จ) */
    public boolean complete(String farmerId, String orderId) {
        try (Session s = sf.openSession()) {
            Transaction tx = s.beginTransaction();
            int updated = s.createNativeQuery("""
                UPDATE perorder
                   SET orderStatus = :st
                 WHERE orderId    = :oid
                   AND farmerId    = :fid
                   AND orderStatus IN (:a,:b)
            """)
            .setParameter("st", ST_COMPLETED)
            .setParameter("oid", orderId)
            .setParameter("fid", farmerId)
            .setParameter("a", ST_SHIPPED)
            .setParameter("b", ST_PREPARING_SHIPMENT)
            .executeUpdate();
            tx.commit();
            return updated > 0;
        }
    }

    /* ====== ลบออเดอร์ฝั่งร้าน (ตามกติกา) ====== */
    public static class DeleteResult {
        public final boolean ok;
        public final String reasonCode;  // not_found / forbidden / not_allowed / error
        public final String reasonThai;
        public final int rowsDeleted;
        private DeleteResult(boolean ok, String code, String thai, int rows) {
            this.ok = ok; this.reasonCode = code; this.reasonThai = thai; this.rowsDeleted = rows;
        }
        public static DeleteResult ok(int rows) { return new DeleteResult(true, null, null, rows); }
        public static DeleteResult err(String code, String thai) { return new DeleteResult(false, code, thai, 0); }
    }

    /**
     * ลบออเดอร์ฝั่งร้าน:
     * - ต้องเป็นออเดอร์ของร้านนั้น
     * - ห้ามลบเมื่อ paymentStatus ∈ {PAID_PENDING_VERIFY, PAID_CONFIRMED, REFUNDED}
     * - ห้ามลบเมื่อ orderStatus ∈ {SHIPPED, COMPLETED}
     */
    public DeleteResult deleteOrderByFarmer(String farmerId, String orderId) {
        if (farmerId == null || orderId == null) return DeleteResult.err("error", "ข้อมูลไม่ครบ");

        try (Session s = sf.openSession()) {
            Object[] row = (Object[]) s.createNativeQuery("""
                SELECT orderStatus, paymentStatus, farmerId
                  FROM perorder
                 WHERE orderId = :oid
            """).setParameter("oid", orderId).uniqueResult();

            if (row == null) return DeleteResult.err("not_found", "ไม่พบออเดอร์");
            String ost = row[0] == null ? "" : row[0].toString();
            String pst = row[1] == null ? "" : row[1].toString();
            String owner = row[2] == null ? "" : row[2].toString();

            if (!farmerId.equals(owner)) return DeleteResult.err("forbidden", "ไม่ใช่ออเดอร์ของร้านคุณ");

            boolean blockedPay = PAY_PAID_PENDING.equalsIgnoreCase(pst)
                              || PAY_PAID_CONFIRMED.equalsIgnoreCase(pst)
                              || PAY_REFUNDED.equalsIgnoreCase(pst);
            boolean blockedOrd = ST_SHIPPED.equalsIgnoreCase(ost)
                              || ST_COMPLETED.equalsIgnoreCase(ost);

            if (blockedPay || blockedOrd) {
                return DeleteResult.err("not_allowed",
                    "ลบไม่ได้: ตั้งแต่สถานะ PAID_PENDING_VERIFY ขึ้นไป หรือเมื่อออเดอร์จัดส่ง/สำเร็จแล้ว");
            }

            Transaction tx = s.beginTransaction();
            int r1 = s.createNativeQuery("DELETE FROM receipt WHERE perorder_orderId = :oid")
                      .setParameter("oid", orderId).executeUpdate();
            int r2 = s.createNativeQuery("DELETE FROM preorderdetail WHERE orderId = :oid")
                      .setParameter("oid", orderId).executeUpdate();
            int r3 = s.createNativeQuery("DELETE FROM perorder WHERE orderId = :oid AND farmerId = :fid")
                      .setParameter("oid", orderId)
                      .setParameter("fid", farmerId)
                      .executeUpdate();
            tx.commit();

            int total = r1 + r2 + r3;
            return (r3 > 0) ? DeleteResult.ok(total)
                            : DeleteResult.err("error", "ลบไม่สำเร็จ");
        } catch (Exception e) {
            return DeleteResult.err("error", "เกิดข้อผิดพลาด: " + e.getMessage());
        }
    }

    // ====== DTOs ======
    public static class OrderHeader {
        private String orderId;
        private java.util.Date orderDate;
        private BigDecimal totalPrice;
        private String orderStatus;
        private String paymentStatus;
        private String memberId;
        private String farmerId;
        private String deliveryDate;
        private String customerName;
        private String customerPhone;
        private String customerAddr;
        private String customerEmail;

        public String getOrderId() { return orderId; }
        public java.util.Date getOrderDate() { return orderDate; }
        public BigDecimal getTotalPrice() { return totalPrice; }
        public String getOrderStatus() { return orderStatus; }
        public String getPaymentStatus() { return paymentStatus; }
        public String getMemberId() { return memberId; }
        public String getFarmerId() { return farmerId; }
        public String getDeliveryDate() { return deliveryDate; }
        public String getCustomerName() { return customerName; }
        public String getCustomerPhone() { return customerPhone; }
        public String getCustomerAddr() { return customerAddr; }
        public String getCustomerEmail() { return customerEmail; }
    }

    public static class OrderItem {
        private String preOrderId;
        private String productId;
        private String productName;
        private String img;
        private BigDecimal price;
        private int qty;
        private BigDecimal lineTotal;
        private String preOrderStatus;

        public String getPreOrderId() { return preOrderId; }
        public String getProductId() { return productId; }
        public String getProductName() { return productName; }
        public String getImg() { return img; }
        public BigDecimal getPrice() { return price; }
        public int getQty() { return qty; }
        public BigDecimal getLineTotal() { return lineTotal; }
        public String getPreOrderStatus() { return preOrderStatus; }
    }

    public static class ReceiptInfo {
        private String receiptId;
        private String referenceId;
        private String img;

        public String getReceiptId() { return receiptId; }
        public String getReferenceId() { return referenceId; }
        public String getImg() { return img; }
    }
}
