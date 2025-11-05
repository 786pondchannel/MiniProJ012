package com.springmvc.service;

import org.hibernate.Session;
import org.hibernate.Transaction;
import org.springframework.stereotype.Service;
import com.springmvc.model.HibernateConnection;

import jakarta.persistence.NoResultException;

/**
 * ลบสินค้าแบบ hard delete:
 * - "ห้ามลบ" ถ้ามีออเดอร์ผูกกับสินค้านี้ (preorderdetail)
 * - ลบรูปจากตาราง product_image แล้วค่อยลบ product
 */
@Service
public class DeleteProductService {

    /** โครงผลลัพธ์แบบบอกเหตุผลได้ */
    public static record DeleteResult(boolean success, String message){}

    /** นับจำนวนการอ้างอิงสินค้านี้ในตาราง preorderdetail */
    public long countPreorderRefs(String productId){
        if (productId == null || productId.trim().isEmpty()) return 0L;
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Number n = (Number) s.createNativeQuery(
                "SELECT COUNT(*) FROM preorderdetail WHERE productId = :pid")
                .setParameter("pid", productId)
                .getSingleResult();
            return n == null ? 0L : n.longValue();
        } catch (NoResultException e) {
            return 0L;
        } catch (Exception ex) {
            ex.printStackTrace();
            return Long.MAX_VALUE; // ป้องกันความเสี่ยง ให้ถือว่าลบไม่ได้
        }
    }

    /** true = ลบได้ (ไม่มีออเดอร์ผูกอยู่) */
    public boolean canHardDelete(String productId){
        return countPreorderRefs(productId) == 0L;
    }

    public DeleteResult hardDeleteByProductId(String productId) {
        if (productId == null || productId.trim().isEmpty())
            return new DeleteResult(false, "ไม่พบรหัสสินค้า");

        // 1) ป้องกันการลบถ้ามีออเดอร์ผูกอยู่
        long refs = countPreorderRefs(productId);
        if (refs > 0) {
            return new DeleteResult(false, "ลบไม่ได้: พบออเดอร์ที่เกี่ยวข้องกับสินค้านี้จำนวน " + refs + " รายการ");
        }

        Session session = null;
        Transaction tx = null;
        try {
            session = HibernateConnection.getSessionFactory().openSession();
            tx = session.beginTransaction();

            // 2) ลบความสัมพันธ์รูป (table: product_image)
            session.createNativeQuery("DELETE FROM product_image WHERE productId = :pid")
                   .setParameter("pid", productId)
                   .executeUpdate();

            // 3) ลบแถวหลักสินค้า
            int affected = session.createNativeQuery("DELETE FROM product WHERE productId = :pid")
                                  .setParameter("pid", productId)
                                  .executeUpdate();

            tx.commit();
            if (affected > 0) {
                return new DeleteResult(true, "ลบสินค้าสำเร็จ");
            } else {
                return new DeleteResult(false, "ไม่พบสินค้าที่ต้องการลบ");
            }
        } catch (Exception ex) {
            if (tx != null) tx.rollback();
            ex.printStackTrace();
            return new DeleteResult(false, "เกิดข้อผิดพลาดระหว่างลบสินค้า");
        } finally {
            if (session != null) session.close();
        }
    }
}
