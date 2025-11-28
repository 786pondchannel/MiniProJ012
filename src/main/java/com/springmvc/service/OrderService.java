package com.springmvc.service;

import com.springmvc.cart.VendorCart;
import com.springmvc.model.CartItem;
import com.springmvc.model.HibernateConnection;
import org.hibernate.Session;
import org.hibernate.Transaction;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.file.*;
import java.sql.*;
import java.time.LocalDate;
import java.util.*;

/** บริการจัดการใบสั่งซื้อ */
@Service
public class OrderService {

    /* ===== ค่าคงที่สถานะ ===== */
    private static final String ORD_SENT_TO_FARMER     = "SENT_TO_FARMER";
    private static final String ORD_FARMER_CONFIRMED   = "FARMER_CONFIRMED";
    private static final String ORD_PREPARING          = "PREPARING_SHIPMENT";
    private static final String ORD_SHIPPED            = "SHIPPED";
    private static final String ORD_COMPLETED          = "COMPLETED";

    private static final String PAY_UNPAID             = "UNPAID";
    private static final String PAY_AWAIT_BUYER        = "AWAITING_BUYER_PAYMENT";
    private static final String PAY_PAID_PENDING       = "PAID_PENDING_VERIFY";
    private static final String PAY_PAID_CONFIRMED     = "PAID_CONFIRMED";

    /* ===== โฟลเดอร์อัปโหลด (อิง env UPLOAD_DIR เหมือน WebConfig) ===== */
    private static Path uploadRoot() {
        String os = System.getProperty("os.name", "").toLowerCase(Locale.ROOT);
        String defaultPath = os.contains("win") ? "D:/Toos/png/" : "/app/uploads/";
        String env = System.getenv().getOrDefault("UPLOAD_DIR", defaultPath);
        return Paths.get(env).toAbsolutePath().normalize();
    }
    private static final Path UPLOAD_ROOT  = uploadRoot();
    private static final Path RECEIPTS_DIR = UPLOAD_ROOT.resolve("receipts"); // /uploads/receipts/*

    @Autowired
    private StockService stockService; // ✅ ใช้ตัดสต๊อก “กิโลกรัม”

    /* ---------- ใช้ใน Controller เพื่อตอบกลับ ---------- */
    public static class DeleteResult {
        public final boolean ok;
        public final String reason;
        public final int rowsDeleted;
        public DeleteResult(boolean ok, String reason, int rowsDeleted) {
            this.ok = ok; this.reason = reason; this.rowsDeleted = rowsDeleted;
        }
        public static DeleteResult ok(int rows) { return new DeleteResult(true, null, rows); }
        public static DeleteResult err(String r) { return new DeleteResult(false, r, 0); }
    }

    public String checkoutOneVendor(String memberId, VendorCart vc) {
        String orderId = UUID.randomUUID().toString();
        BigDecimal total = vc.getSubtotal();

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();

            String farmerId = null;
            try { farmerId = (String) VendorCart.class.getMethod("getFarmerId").invoke(vc); }
            catch (Exception ignore) { }

            List<CartItem> items = vc.getItems();
            if ((farmerId == null || farmerId.isBlank()) && items != null && !items.isEmpty()) {
                String firstProdId = items.get(0).getProductId();
                Object f = s.createNativeQuery("SELECT farmerId FROM product WHERE productId = :pid")
                        .setParameter("pid", firstProdId)
                        .uniqueResult();
                farmerId = (f == null) ? null : f.toString();
            }
            if (farmerId == null || farmerId.isBlank()) {
                tx.rollback();
                throw new IllegalStateException("ไม่พบ farmerId ของออเดอร์นี้");
            }

            // 1) สร้างหัวออเดอร์
            s.createNativeQuery("""
                INSERT INTO perorder(orderId, orderDate, totalPrice, orderStatus, memberId, farmerId, paymentStatus, DeliveryDate)
                VALUES (:id, :odate, :total, :st, :mid, :fid, :pstat, :dd)
            """)
            .setParameter("id", orderId)
            .setParameter("odate", java.sql.Date.valueOf(LocalDate.now()))
            .setParameter("total", total)
            .setParameter("st", ORD_SENT_TO_FARMER)
            .setParameter("mid", memberId)
            .setParameter("fid", farmerId)
            .setParameter("pstat", PAY_UNPAID)
            .setParameter("dd", "TBD")
            .executeUpdate();

            // 2) แทรกรายการ + หักสต๊อกกิโลภายในทรานแซคชันเดียว
            s.doWork(conn -> {
                boolean hasQtyKg = hasColumn(conn, "preorderdetail", "quantityKg");

                final String sqlInsert = hasQtyKg
                        ? "INSERT INTO preorderdetail(preOrderId, quantity, quantityKg, preOrderStatus, orderId, productId) VALUES (?,?,?,?,?,?)"
                        : "INSERT INTO preorderdetail(preOrderId, quantity, preOrderStatus, orderId, productId) VALUES (?,?,?,?,?)";

                try (PreparedStatement ps = conn.prepareStatement(sqlInsert)) {
                    for (CartItem it : items) {
                        String preId = UUID.randomUUID().toString();

                        // kg จากตะกร้า (ถ้าไม่ใส่มา ใช้ qty เป็น kg 1:1)
                        BigDecimal kg = it.getQtyKg();
                        if (kg == null || kg.signum() <= 0) {
                            kg = BigDecimal.valueOf(Math.max(0, it.getQty()));
                        }
                        // จำนวนชิ้น (เผื่อหน้าเดิมยังใช้) → ถ้าไม่มี ให้ ceil ของ kg
                        int qtyPiece = it.getQty() > 0
                                ? it.getQty()
                                : kg.setScale(0, RoundingMode.CEILING).intValue();

                        // ✅ ตัดสต๊อกเป็น “กิโลกรัม” แบบอะตอมมิก
                        boolean ok = stockService.decreaseStockKg(conn, it.getProductId(), kg);
                        if (!ok) {
                            throw new SQLException("สต๊อกไม่พอ: " + it.getProductId() + " ต้องการ " + kg + " กก.");
                        }

                        // บันทึกรายการ
                        if (hasQtyKg) {
                            ps.setString(1, preId);
                            ps.setInt(2, qtyPiece);
                            ps.setBigDecimal(3, kg);
                            ps.setString(4, "PENDING");
                            ps.setString(5, orderId);
                            ps.setString(6, it.getProductId());
                        } else {
                            ps.setString(1, preId);
                            ps.setInt(2, qtyPiece);
                            ps.setString(3, "PENDING");
                            ps.setString(4, orderId);
                            ps.setString(5, it.getProductId());
                        }
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }
            });

            tx.commit();
        }
        return orderId;
    }

    /* ============== คงโฟลว์ถัดไปเหมือนเดิม แต่ “ไม่หักสต๊อกซ้ำ” ตอนยืนยันชำระเงิน ============== */

    public void farmerConfirmOrder(String orderId, String farmerId) {
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();

            int a = s.createNativeQuery("""
                UPDATE perorder
                   SET orderStatus   = :st,
                       paymentStatus = :pstat
                 WHERE orderId = :oid
                   AND farmerId = :fid
            """)
            .setParameter("st", ORD_FARMER_CONFIRMED)
            .setParameter("pstat", PAY_AWAIT_BUYER)
            .setParameter("oid", orderId)
            .setParameter("fid", farmerId)
            .executeUpdate();

            if (a > 0) {
                s.createNativeQuery("""
                    UPDATE preorderdetail
                       SET preOrderStatus = :pst
                     WHERE orderId = :oid
                """)
                .setParameter("pst", "CONFIRMED")
                .setParameter("oid", orderId)
                .executeUpdate();
            }

            tx.commit();
        }
    }

    /* ========================= ยืนยันชำระเงิน → อัปเดตสถานะอย่างเดียว =========================
       (สต๊อกถูกตัดไปแล้วตอน checkout)
    ======================================================================== */
    public void farmerVerifyPayment(String orderId, String farmerId) {
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();
            s.createNativeQuery("""
                UPDATE perorder
                   SET paymentStatus = :pstat
                 WHERE orderId = :oid
                   AND farmerId = :fid
                   AND paymentStatus IN (:pending, :await)
            """)
            .setParameter("pstat",  PAY_PAID_CONFIRMED)
            .setParameter("oid",    orderId)
            .setParameter("fid",    farmerId)
            .setParameter("pending",PAY_PAID_PENDING)
            .setParameter("await",  PAY_AWAIT_BUYER)
            .executeUpdate();
            tx.commit();
        }
    }

    /* ========================= HARD DELETE โดยผู้ซื้อ =========================
       ลบได้เฉพาะช่วงขั้น 1–2:
       - orderStatus ∈ {SENT_TO_FARMER, FARMER_CONFIRMED}
       - paymentStatus ∈ {AWAITING_BUYER_PAYMENT, PAID_PENDING_VERIFY}
       (หมายเหตุ: ถ้าต้องการคืนสต๊อกเมื่อยกเลิกก่อนชำระเงิน ให้เพิ่ม logic คืนสต๊อกที่นี่)
    ========================================================================== */
    public DeleteResult hardDeleteByBuyer(String orderId, String memberId) {
        if (orderId == null || memberId == null) return DeleteResult.err("invalid");

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Object[] row = (Object[]) s.createNativeQuery("""
                SELECT memberId, orderStatus, paymentStatus
                  FROM perorder
                 WHERE orderId = :oid
            """).setParameter("oid", orderId).uniqueResult();

            if (row == null) return DeleteResult.err("not_found");

            String owner = String.valueOf(row[0]);
            String ost   = row[1] == null ? "" : row[1].toString();
            String pst   = row[2] == null ? "" : row[2].toString();

            if (!memberId.equals(owner)) return DeleteResult.err("forbidden");

            boolean orderOK = ORD_SENT_TO_FARMER.equalsIgnoreCase(ost) || ORD_FARMER_CONFIRMED.equalsIgnoreCase(ost);
            boolean payOK   = PAY_AWAIT_BUYER.equalsIgnoreCase(pst) || PAY_PAID_PENDING.equalsIgnoreCase(pst);

            if (!(orderOK && payOK)) return DeleteResult.err("cannot_delete_after_step2");

            // เก็บ path สลิปไว้ลบไฟล์หลัง commit
            @SuppressWarnings("unchecked")
            List<String> imgs = s.createNativeQuery("""
                SELECT Img FROM receipt WHERE perorder_orderId = :oid
            """).setParameter("oid", orderId).list();

            Transaction tx = s.beginTransaction();

            int r1 = s.createNativeQuery("DELETE FROM receipt WHERE perorder_orderId = :oid")
                      .setParameter("oid", orderId).executeUpdate();

            int r2 = s.createNativeQuery("DELETE FROM preorderdetail WHERE orderId = :oid")
                      .setParameter("oid", orderId).executeUpdate();

            int r3 = s.createNativeQuery("DELETE FROM perorder WHERE orderId = :oid AND memberId = :mid")
                      .setParameter("oid", orderId)
                      .setParameter("mid", memberId)
                      .executeUpdate();

            tx.commit();

            // ลบไฟล์ภาพสลิปในดิสก์ (ถ้ามี)
            if (imgs != null) {
                for (String im : imgs) {
                    try {
                        Path p = resolveReceiptPath(im);
                        if (p != null) Files.deleteIfExists(p);
                    } catch (Exception ignore) { }
                }
            }

            int total = r1 + r2 + r3;
            return (r3 > 0) ? DeleteResult.ok(total) : DeleteResult.err("delete_failed");
        }
    }

    /* ===== helper: map Img -> Path (จำกัดให้อยู่ใต้ UPLOAD_ROOT เท่านั้น) ===== */
    private Path resolveReceiptPath(String img){
        if (img == null || img.isBlank()) return null;
        String clean = img.trim().replace("\\","/");

        // absolute → อนุญาตเฉพาะที่อยู่ใต้ UPLOAD_ROOT
        Path abs = Paths.get(clean);
        if (abs.isAbsolute()) {
            Path norm = abs.normalize().toAbsolutePath();
            if (norm.startsWith(UPLOAD_ROOT) && Files.isRegularFile(norm)) return norm;
            return null; // ไม่ลบไฟล์นอกโฟลเดอร์อัปโหลด
        }

        // relative → รองรับหลายรูปแบบ
        if (clean.startsWith("/")) clean = clean.substring(1);
        if (clean.startsWith("uploads/")) clean = clean.substring("uploads/".length());
        if (clean.startsWith("receipts/")) {
            Path p = RECEIPTS_DIR.resolve(clean.substring("receipts/".length())).normalize();
            return Files.isRegularFile(p) ? p : null;
        }

        // default → ลองแมปเข้าที่ /receipts
        Path p = RECEIPTS_DIR.resolve(clean).normalize();
        return Files.isRegularFile(p) ? p : null;
    }

    public boolean cancelByBuyer(String orderId, String memberId) {
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Object[] row = (Object[]) s.createNativeQuery("""
                SELECT orderStatus, paymentStatus, memberId
                  FROM perorder
                 WHERE orderId = :oid
            """).setParameter("oid", orderId).uniqueResult();

            if (row == null) return false;
            if (!Objects.equals(memberId, row[2] == null ? null : row[2].toString())) return false;

            String ost = row[0] == null ? "" : row[0].toString();
            String pst = row[1] == null ? "" : row[1].toString();

            boolean allowed = "SENT_TO_FARMER".equals(ost)
                    || ("FARMER_CONFIRMED".equals(ost) && "AWAITING_BUYER_PAYMENT".equals(pst));
            if (!allowed) return false;

            var tx = s.beginTransaction();
            s.createNativeQuery("DELETE FROM receipt WHERE perorder_orderId = :oid")
                    .setParameter("oid", orderId).executeUpdate();
            s.createNativeQuery("DELETE FROM preorderdetail WHERE orderId = :oid")
                    .setParameter("oid", orderId).executeUpdate();
            int del = s.createNativeQuery("DELETE FROM perorder WHERE orderId = :oid AND memberId = :mid")
                    .setParameter("oid", orderId)
                    .setParameter("mid", memberId)
                    .executeUpdate();
            tx.commit();
            return del > 0;
        } catch (Exception e) {
            return false;
        }
    }

    /* ===== DB metadata helpers ===== */
    private static boolean hasColumn(Connection conn, String tableName, String columnName) {
        try {
            DatabaseMetaData md = conn.getMetaData();
            try (ResultSet rs = md.getColumns(null, null, tableName, "%")) {
                while (rs.next()) {
                    String col = rs.getString("COLUMN_NAME");
                    if (col != null && col.equalsIgnoreCase(columnName)) return true;
                }
            }
        } catch (SQLException ignore) { }
        return false;
    }
}
