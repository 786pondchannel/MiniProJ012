package com.springmvc.model;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Objects;

/**
 * รายการในตะกร้า
 * - ราคา (price) ถือว่าเป็น "ราคาต่อกิโลกรัม" ณ เวลาหยิบลงตะกร้า
 * - ถ้ามี qtyKg (> 0) จะคิดยอดโดยใช้กิโลกรัม
 * - ถ้า qtyKg ว่าง/<=0 จะตกกลับไปใช้ qty (จำนวนชิ้น) เพื่อความเข้ากันได้กับโค้ดเดิม
 */
public class CartItem {

    private String productId;
    private String productName;
    private String img;

    /** ราคาต่อหน่วย (ต่อกิโลกรัม) ณ เวลาหยิบลงตะกร้า */
    private BigDecimal price;

    /** จำนวนชิ้น (ของเดิม) — คงไว้เพื่อ compatibility */
    private int qty;

    /** จำนวนกิโลกรัม (ใหม่) — ถ้ามีให้ใช้ค่านี้ตัดสต๊อก/คำนวณยอด */
    private BigDecimal qtyKg;

    /* ===================== Constructors ===================== */

    public CartItem() {
    }

    public CartItem(String productId, String productName, String img, BigDecimal price, int qty) {
        this.productId = productId;
        this.productName = productName;
        this.img = img;
        this.price = safePrice(price);
        this.qty = Math.max(0, qty);
        this.qtyKg = null;
    }

    public CartItem(String productId, String productName, String img, BigDecimal price, BigDecimal qtyKg) {
        this.productId = productId;
        this.productName = productName;
        this.img = img;
        this.price = safePrice(price);
        setQtyKg(qtyKg); // จะ normalize scale ให้เอง
        this.qty = 0;    // เมื่อใช้ kg เป็นหลัก ไม่จำเป็นต้องเก็บ qty ชิ้น
    }

    /* ===================== Business Helpers ===================== */

    /**
     * คืนยอดรวมของรายการ:
     * - ถ้า qtyKg > 0: ใช้ price * qtyKg
     * - ไม่เช่นนั้น: ใช้ price * qty (จำนวนชิ้น)
     * ปัดเศษทศนิยม 2 ตำแหน่ง (เงิน)
     */
    public BigDecimal getSubtotal() {
        BigDecimal p = (price == null) ? BigDecimal.ZERO : price;
        if (qtyKg != null && qtyKg.compareTo(BigDecimal.ZERO) > 0) {
            return p.multiply(qtyKg).setScale(2, RoundingMode.HALF_UP);
        }
        return p.multiply(BigDecimal.valueOf(Math.max(0, qty))).setScale(2, RoundingMode.HALF_UP);
    }

    /** จำนวนที่จะใช้ตัดสต๊อกในรูปแบบ "กิโลกรัม" (fallback จาก qty เป็น kg=qty*1) */
    public BigDecimal getEffectiveQtyKg() {
        if (qtyKg != null && qtyKg.compareTo(BigDecimal.ZERO) > 0) return qtyKg;
        return BigDecimal.valueOf(Math.max(0, qty)).setScale(3, RoundingMode.HALF_UP);
    }

    /** เพิ่ม kg เข้าไป (ค่าลบจะถูกเพิกเฉย) */
    public void addQtyKg(BigDecimal add) {
        if (add == null || add.compareTo(BigDecimal.ZERO) <= 0) return;
        if (this.qtyKg == null) this.qtyKg = BigDecimal.ZERO;
        this.qtyKg = this.qtyKg.add(add).setScale(3, RoundingMode.HALF_UP);
    }

    /** เพิ่มจำนวนชิ้น (ของเดิม) */
    public void addQty(int add) {
        if (add <= 0) return;
        this.qty += add;
        if (this.qty < 0) this.qty = 0;
    }

    /* ===================== Getters / Setters ===================== */

    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }

    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }

    public String getImg() { return img; }
    public void setImg(String img) { this.img = img; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = safePrice(price); }

    /** จำนวนชิ้น (ใช้เมื่อระบบเก่ายังส่งมาเป็นจำนวนชิ้น) */
    public int getQty() { return qty; }
    public void setQty(int qty) { this.qty = Math.max(0, qty); }

    /** จำนวนเป็นกิโลกรัม — จะ normalize เป็น scale(3) และไม่ให้ติดลบ */
    public BigDecimal getQtyKg() { return qtyKg; }
    public void setQtyKg(BigDecimal qtyKg) {
        if (qtyKg == null) { this.qtyKg = null; return; }
        BigDecimal v = qtyKg;
        if (v.compareTo(BigDecimal.ZERO) < 0) v = BigDecimal.ZERO;
        this.qtyKg = v.setScale(3, RoundingMode.HALF_UP);
    }

    /* ===================== Utils ===================== */

    private static BigDecimal safePrice(BigDecimal p) {
        if (p == null) return BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        if (p.compareTo(BigDecimal.ZERO) < 0) p = BigDecimal.ZERO;
        return p.setScale(2, RoundingMode.HALF_UP);
    }

    @Override
    public String toString() {
        return "CartItem{" +
                "productId='" + productId + '\'' +
                ", productName='" + productName + '\'' +
                ", price=" + price +
                ", qty=" + qty +
                ", qtyKg=" + qtyKg +
                '}';
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof CartItem)) return false;
        CartItem cartItem = (CartItem) o;
        return Objects.equals(productId, cartItem.productId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(productId);
    }
}
