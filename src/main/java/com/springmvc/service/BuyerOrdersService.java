package com.springmvc.service;

import com.springmvc.model.HibernateConnection;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.Transaction;
import org.hibernate.query.NativeQuery;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
public class BuyerOrdersService {

    private final SessionFactory sf = HibernateConnection.getSessionFactory();

    // ====== DTOs ที่ JSP ต้องมี getter ======
    public static class OrderDetail {
        private String orderId;
        private java.util.Date orderDate;
        private BigDecimal totalPrice;
        private String orderStatus;
        private String paymentStatus;
        private String memberId;
        private String farmerId;
        private String deliveryDate;

        // getters
        public String getOrderId() { return orderId; }
        public java.util.Date getOrderDate() { return orderDate; }
        public BigDecimal getTotalPrice() { return totalPrice; }
        public String getOrderStatus() { return orderStatus; }
        public String getPaymentStatus() { return paymentStatus; }
        public String getMemberId() { return memberId; }
        public String getFarmerId() { return farmerId; }
        public String getDeliveryDate() { return deliveryDate; }

        // setters
        public void setOrderId(String orderId) { this.orderId = orderId; }
        public void setOrderDate(java.util.Date orderDate) { this.orderDate = orderDate; }
        public void setTotalPrice(BigDecimal totalPrice) { this.totalPrice = totalPrice; }
        public void setOrderStatus(String orderStatus) { this.orderStatus = orderStatus; }
        public void setPaymentStatus(String paymentStatus) { this.paymentStatus = paymentStatus; }
        public void setMemberId(String memberId) { this.memberId = memberId; }
        public void setFarmerId(String farmerId) { this.farmerId = farmerId; }
        public void setDeliveryDate(String deliveryDate) { this.deliveryDate = deliveryDate; }
    }

    public static class OrderLine {
        private String preOrderId;
        private String productId;
        private String productName;
        private String img;
        private BigDecimal price;
        private Integer qty;          // ใช้เมื่อเป็นจำนวนชิ้น
        private BigDecimal qtyKg;     // ใช้เมื่อเป็นกิโลกรัม
        private BigDecimal lineTotal;
        private String preOrderStatus;

        // getters
        public String getPreOrderId() { return preOrderId; }
        public String getProductId() { return productId; }
        public String getProductName() { return productName; }
        public String getImg() { return img; }
        public BigDecimal getPrice() { return price; }
        public Integer getQty() { return qty; }
        public BigDecimal getQtyKg() { return qtyKg; }
        public BigDecimal getLineTotal() { return lineTotal; }
        public String getPreOrderStatus() { return preOrderStatus; }

        // setters
        public void setPreOrderId(String preOrderId) { this.preOrderId = preOrderId; }
        public void setProductId(String productId) { this.productId = productId; }
        public void setProductName(String productName) { this.productName = productName; }
        public void setImg(String img) { this.img = img; }
        public void setPrice(BigDecimal price) { this.price = price; }
        public void setQty(Integer qty) { this.qty = qty; }
        public void setQtyKg(BigDecimal qtyKg) { this.qtyKg = qtyKg; }
        public void setLineTotal(BigDecimal lineTotal) { this.lineTotal = lineTotal; }
        public void setPreOrderStatus(String preOrderStatus) { this.preOrderStatus = preOrderStatus; }
    }

    public static class ReceiptInfo {
        private String receiptId;
        private String referenceId;
        private String img;

        // getters
        public String getReceiptId() { return receiptId; }
        public String getReferenceId() { return referenceId; }
        public String getImg() { return img; }

        // setters
        public void setReceiptId(String receiptId) { this.receiptId = receiptId; }
        public void setReferenceId(String referenceId) { this.referenceId = referenceId; }
        public void setImg(String img) { this.img = img; }
    }

    // ====== ตรวจว่ามีคอลัมน์ quantityKg หรือไม่ ======
    public boolean hasQuantityKgColumn() {
        try (Session s = sf.openSession()) {
            try {
                s.createNativeQuery("SELECT quantityKg FROM preorderdetail WHERE 1=0").list();
                return true;
            } catch (Exception ignore) {
                return false;
            }
        }
    }

    /** Header ออเดอร์ (ตรวจว่าเป็นของผู้ซื้อนั้นจริง) */
    public OrderDetail getDetail(String memberId, String orderId) {
        try (Session s = sf.openSession()) {
            Object[] row = (Object[]) s.createNativeQuery("""
                SELECT o.orderId, o.orderDate, o.totalPrice, o.orderStatus, o.paymentStatus,
                       o.memberId, o.farmerId, o.DeliveryDate
                  FROM perorder o
                 WHERE o.orderId = :oid AND o.memberId = :mid
            """)
            .setParameter("oid", orderId)
            .setParameter("mid", memberId)
            .uniqueResult();

            if (row == null) return null;

            int i = 0;
            OrderDetail od = new OrderDetail();
            od.setOrderId((String) row[i++]);
            Date odt = (Date) row[i++];
            od.setOrderDate(odt == null ? null : new java.util.Date(odt.getTime()));
            od.setTotalPrice((BigDecimal) row[i++]);
            od.setOrderStatus((String) row[i++]);
            od.setPaymentStatus((String) row[i++]);
            od.setMemberId((String) row[i++]);
            od.setFarmerId((String) row[i++]);
            od.setDeliveryDate((String) row[i++]);
            return od;
        }
    }

    /** รายการสินค้าในออเดอร์ (เลือกใช้ quantityKg ถ้ามี) */
    @SuppressWarnings("unchecked")
    public List<OrderLine> getLines(String memberId, String orderId) {
        boolean useKg = hasQuantityKgColumn();
        String qtyExpr = useKg ? "d.quantityKg" : "d.quantity";

        try (Session s = sf.openSession()) {
            List<Object[]> rows = s.createNativeQuery("""
                SELECT d.preOrderId,
                       d.productId,
                       p.Productname,
                       p.Img,
                       p.price,
                       %s AS qty_any,
                       (p.price * %s) AS lineTotal,
                       d.preOrderStatus
                  FROM preorderdetail d
                  JOIN product p  ON p.productId = d.productId
                  JOIN perorder o ON o.orderId   = d.orderId
                 WHERE d.orderId  = :oid
                   AND o.memberId = :mid
                 ORDER BY p.Productname ASC
            """.formatted(qtyExpr, qtyExpr))
            .setParameter("oid", orderId)
            .setParameter("mid", memberId)
            .list();

            List<OrderLine> list = new ArrayList<>();
            for (Object[] r : rows) {
                int i = 0;
                OrderLine it = new OrderLine();
                it.setPreOrderId((String) r[i++]);
                it.setProductId((String) r[i++]);
                it.setProductName((String) r[i++]);
                it.setImg((String) r[i++]);
                it.setPrice((BigDecimal) r[i++]);

                Number qn = (Number) r[i++];
                it.setLineTotal((BigDecimal) r[i++]);
                it.setPreOrderStatus((String) r[i++]);

                if (useKg) {
                    it.setQtyKg(qn == null ? BigDecimal.ZERO : new BigDecimal(qn.toString()));
                    it.setQty(null);
                } else {
                    it.setQty(qn == null ? 0 : qn.intValue());
                    it.setQtyKg(null);
                }
                list.add(it);
            }
            return list;
        }
    }

    /** หลักฐานการชำระเงิน */
    @SuppressWarnings("unchecked")
    public List<ReceiptInfo> getReceipts(String memberId, String orderId) {
        try (Session s = sf.openSession()) {
            Long owned = ((Number) s.createNativeQuery(
                "SELECT COUNT(*) FROM perorder WHERE orderId=:oid AND memberId=:mid"
            ).setParameter("oid", orderId)
             .setParameter("mid", memberId)
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
                ri.setReceiptId((String) r[0]);
                ri.setReferenceId((String) r[1]);
                ri.setImg((String) r[2]);
                list.add(ri);
            }
            return list;
        }
    }

    // (ถ้ามีเมธอด action อื่น ๆ คงไว้ได้ตามเดิม)
}
