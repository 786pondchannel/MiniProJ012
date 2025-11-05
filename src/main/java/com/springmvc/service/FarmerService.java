package com.springmvc.service;

import com.springmvc.model.HibernateConnection;
import com.springmvc.model.Member;
import com.springmvc.model.Farmer;
import com.springmvc.model.Product;
import com.springmvc.model.Review;

import org.hibernate.Session;
import org.hibernate.Transaction;
import org.hibernate.query.Query;
import org.springframework.stereotype.Service;

import java.lang.reflect.Method;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class FarmerService {

    /* ===================== ใช้ใน CartController ===================== */

    public String getFarmName(String farmerId) {
        Farmer f = getFarmer(farmerId);
        if (f == null) return null;
        String name = getStringByGetters(f, "getFarmName", "getStoreName", "getFarmerName", "getName");
        return (name == null || name.isBlank()) ? null : name.trim();
    }

    /* ===================== ใช้ใน FarmerController ===================== */

    public String resolveFarmerIdFromMember(Member member) {
        if (member == null) return null;
        String guess = member.getMemberId();

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Farmer f = s.get(Farmer.class, guess);
            if (f != null) return getStringByGetters(f, "getFarmerId", "getId");

            List<Farmer> list = tryQueryFarmers(s,
                    List.of("from Farmer f where f.memberId = :id",
                            "from Farmer f where f.member.memberId = :id",
                            "from Farmer f where f.userId = :id"),
                    "id", guess, 1);
            if (!list.isEmpty()) return getStringByGetters(list.get(0), "getFarmerId", "getId");
        } catch (Exception ignore) {}
        return guess;
    }

    public Farmer getFarmer(String farmerId) {
        if (farmerId == null || farmerId.isBlank()) return null;
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Farmer f = s.get(Farmer.class, farmerId);
            if (f != null) return f;

            List<Farmer> list = tryQueryFarmers(s,
                    List.of(
                            "from Farmer f where f.farmerId = :id",
                            "from Farmer f where f.id = :id",
                            "from Farmer f where f.memberId = :id",
                            "from Farmer f where f.userId = :id"
                    ),
                    "id", farmerId, 1
            );
            return list.isEmpty() ? null : list.get(0);
        }
    }

    /** แกลเลอรีรูปของฟาร์ม (จาก FarmerImage + ฟิลด์ใน Farmer) */
    public List<String> getFarmerGallery(String farmerId) {
        if (farmerId == null || farmerId.isBlank()) return Collections.emptyList();

        List<String> out = new ArrayList<>();

        // 1) จาก FarmerImage
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            List<?> imgs = tryQueryGeneric(s,
                List.of(
                    "from com.springmvc.model.FarmerImage g where g.farmerId = :id order by g.sortOrder asc",
                    "from com.springmvc.model.FarmerImage g where g.farmer.farmerId = :id order by g.sortOrder asc",
                    "from com.springmvc.model.FarmerImage g where g.farmerID = :id order by g.id asc",
                    "from com.springmvc.model.FarmerImage g order by g.id asc"
                ),
                "id", farmerId, 300
            );

            for (Object item : imgs) {
                String owner = getStringByGetters(item, "getFarmerId","getFarmerID");
                if (owner == null) {
                    Object fObj = getObjectByGetters(item, "getFarmer");
                    if (fObj != null) owner = getStringByGetters(fObj, "getFarmerId","getId");
                }
                if (owner != null && !owner.equalsIgnoreCase(farmerId)) continue;

                String raw = getStringByGetters(item,
                        "getImageUrl","getUrl","getPath","getFileName","getFilename","getImg","getImage");
                String normalized = normalizeForJsp(raw);
                addIfPresent(out, normalized);
            }
        } catch (Exception ignore) {}

        // 2) ฟิลด์ใน Farmer เอง
        Farmer farmer = getFarmer(farmerId);
        if (farmer != null) {
            String[] singleFields = { "getImageF", "getImageCover", "getHero", "getCover" };
            for (String g : singleFields) addIfPresent(out, normalizeForJsp(getStringByGetters(farmer, g)));

            for (int i = 1; i <= 10; i++) {
                addIfPresent(out, normalizeForJsp(getStringByGetters(farmer, "getImage"+i, "getImg"+i, "getGallery"+i)));
            }

            String csv = getStringByGetters(farmer, "getGallery","getImages","getGalleryImages");
            if (csv != null) {
                for (String piece : csv.split("[,;\\s]+")) addIfPresent(out, normalizeForJsp(piece));
            }

            String imageF = normalizeForJsp(getStringByGetters(farmer, "getImageF", "getImageCover", "getCover", "getHero"));
            if (imageF != null && out.contains(imageF)) { out.remove(imageF); out.add(0, imageF); }
        }

        return out.stream().filter(s -> s != null && !s.isBlank()).distinct().collect(Collectors.toList());
    }

    /** URL/ไฟล์ QR ของร้าน (ลองหลายชื่อฟิลด์ + normalize พาธ) */
    public String getPaymentSlipUrlFromFarmer(Farmer farmer) {
        if (farmer == null) return null;

        String s = getStringByGetters(farmer,
                "getPaymentSlipUrl","getPaymentSlip","getSlipUrl","getSlip",
                "getQrImageUrl","getQrImage","getQrUrl","getQr",
                "getPromptpayQr","getPromptPayQr","getPromptpay","getPromptPay",
                "getBankQr","getBankQR","getQrCode","getQrcode","getQRCode");
        if (s == null) {
            Object pay = getObjectByGetters(farmer, "getPayment","getBank","getAccount");
            if (pay != null) {
                s = getStringByGetters(pay,
                        "getPaymentSlipUrl","getPaymentSlip","getSlipUrl","getSlip",
                        "getQrImageUrl","getQrImage","getQrUrl","getQr",
                        "getPromptpayQr","getPromptPayQr","getPromptpay","getPromptPay",
                        "getBankQr","getBankQR","getQrCode","getQrcode","getQRCode");
            }
        }
        return normalizeForJsp(s);
    }

    /** สินค้าทั้งหมดของฟาร์ม */
    public List<Product> getProductsOfFarmer(String farmerId) {
        if (farmerId == null || farmerId.isBlank()) return Collections.emptyList();
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            List<Product> list = tryQueryProducts(s,
                    List.of(
                            "from Product p where p.farmerId = :id order by p.productId desc",
                            "from Product p where p.farmer.farmerId = :id order by p.productId desc",
                            "from Product p where p.farmerID = :id order by p.productId desc",
                            "from Product p order by p.productId desc"
                    ),
                    "id", farmerId, 500
            );
            return list.stream().filter(p -> {
                String owner = getStringByGetters(p, "getFarmerId", "getFarmerID");
                if (owner == null) {
                    Object fObj = getObjectByGetters(p, "getFarmer");
                    if (fObj != null) owner = getStringByGetters(fObj, "getFarmerId", "getId");
                }
                return owner != null && owner.equalsIgnoreCase(farmerId);
            }).collect(Collectors.toList());
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    /* ===================== รีวิว (ตาม schema จริง: ไม่มี farmerId ในตาราง review) ===================== */

    /** เพิ่มรีวิวแบบง่าย: ถ้าไม่ส่ง productId จะหยิบสินค้าชิ้นแรกของฟาร์มให้ */
    public String addReviewSimple(String farmerId, String memberId,
                                  String orderId, String productId,
                                  int rating, String comment) {
        if (rating < 1) rating = 1;
        if (rating > 5) rating = 5;

        // ถ้าไม่มี productId ให้หยิบสินค้าชิ้นแรกของฟาร์ม
        if ((productId == null || productId.isBlank()) && farmerId != null && !farmerId.isBlank()) {
            List<Product> ps = getProductsOfFarmer(farmerId);
            if (!ps.isEmpty()) productId = getStringByGetters(ps.get(0), "getProductId","getId");
        }
        if (productId == null || productId.isBlank())
            throw new IllegalArgumentException("productId required (ไม่พบสินค้าในฟาร์มนี้)");

        String reviewId = UUID.randomUUID().toString();

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();

            Review r = new Review();
            r.setReviewId(reviewId);
            r.setProductId(productId);
            r.setMemberId(memberId == null ? "anonymous" : memberId);
            r.setOrderId(orderId);
            r.setRating(rating);
            r.setComment(comment == null ? "" : comment.trim());
            // --- FIX: Review.reviewDate เป็น LocalDate ---
            r.setReviewDate(LocalDate.now());   // << เปลี่ยนจาก new java.util.Date()

            s.persist(r);
            tx.commit();
            return reviewId;
        }
    }

    /** ดึงรีวิวของ "ร้าน" = ดึง productId ทั้งหมดของร้าน แล้วคิวรี review ตาม productId เหล่านั้น */
    public List<Review> getReviews(String farmerId) {
        if (farmerId == null || farmerId.isBlank()) return Collections.emptyList();

        List<Product> products = getProductsOfFarmer(farmerId);
        if (products.isEmpty()) return Collections.emptyList();

        List<String> pids = products.stream()
                .map(p -> getStringByGetters(p, "getProductId","getId"))
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());
        if (pids.isEmpty()) return Collections.emptyList();

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Query<Review> q = s.createQuery(
                    "from com.springmvc.model.Review r where r.productId in (:ids) order by r.reviewDate desc",
                    Review.class
            );
            q.setParameterList("ids", pids);
            q.setMaxResults(300);
            return q.list();
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    /** คะแนนเฉลี่ยจากรีวิวของร้าน */
    public Double getAvgRating(String farmerId) {
        List<Review> rs = getReviews(farmerId);
        if (rs.isEmpty()) return 0d;
        double sum = 0; int n = 0;
        for (Review r : rs) {
            if (r.getRating() != null) { sum += r.getRating(); n++; }
        }
        return n == 0 ? 0d : sum / n;
    }

    /** จำนวนรีวิวของร้าน */
    public Integer getReviewCount(String farmerId) {
        return getReviews(farmerId).size();
    }

    /** นับจำนวนสินค้าในตะกร้า (สำหรับ badge) */
    public int computeCartCount(Object cartObject) {
        if (cartObject == null) return 0;
        try {
            Method m = cartObject.getClass().getMethod("getTotalItems");
            Object v = m.invoke(cartObject);
            if (v instanceof Number n) return n.intValue();
        } catch (Exception ignore) {}
        int sum = 0;
        try {
            Object byFarmer = getObjectByGetters(cartObject, "getByFarmer");
            if (byFarmer instanceof Map<?,?> map) {
                for (Object vc : map.values()) {
                    Object items = getObjectByGetters(vc, "getItems");
                    if (items instanceof Collection<?> col) {
                        for (Object it : col) {
                            Number q = (Number) getObjectByGetters(it, "getQty","getQuantity");
                            if (q != null) sum += q.intValue();
                        }
                    }
                }
            }
        } catch (Exception ignore) {}
        return sum;
    }

    /* ===================== HQL helpers ===================== */

    private List<Farmer> tryQueryFarmers(Session s, List<String> hqls, String param, String value, int max) {
        for (String hql : hqls) {
            try {
                Query<Farmer> q = s.createQuery(hql, Farmer.class);
                if (hql.contains(":" + param)) q.setParameter(param, value);
                if (max > 0) q.setMaxResults(max);
                List<Farmer> rs = q.list();
                if (!rs.isEmpty()) return rs;
            } catch (Exception ignore) {}
        }
        return Collections.emptyList();
    }

    private List<Product> tryQueryProducts(Session s, List<String> hqls, String param, String value, int max) {
        for (String hql : hqls) {
            try {
                Query<Product> q = s.createQuery(hql, Product.class);
                if (hql.contains(":" + param)) q.setParameter(param, value);
                if (max > 0) q.setMaxResults(max);
                List<Product> rs = q.list();
                if (!rs.isEmpty()) return rs;
            } catch (Exception ignore) {}
        }
        return Collections.emptyList();
    }

    private List<?> tryQueryGeneric(Session s, List<String> hqls, String param, String value, int max) {
        for (String hql : hqls) {
            try {
                Query<?> q = s.createQuery(hql);
                if (hql.contains(":" + param)) q.setParameter(param, value);
                if (max > 0) q.setMaxResults(max);
                List<?> rs = q.list();
                if (!rs.isEmpty()) return rs;
            } catch (Exception ignore) {}
        }
        return Collections.emptyList();
    }

    /* ===================== Reflection / Utils ===================== */

    private static String getStringByGetters(Object bean, String... getters) {
        Object v = getObjectByGetters(bean, getters);
        return (v instanceof String s && !s.isBlank()) ? s.trim() : null;
    }

    private static Object getObjectByGetters(Object bean, String... getters) {
        if (bean == null) return null;
        for (String g : getters) {
            try {
                Method m = bean.getClass().getMethod(g);
                Object v = m.invoke(bean);
                if (v != null) return v;
            } catch (Exception ignore) {}
        }
        return null;
    }

    /** ทำความสะอาดพาธรูปให้เข้ากับกติกา JSP */
    private static String normalizeForJsp(String raw) {
        if (raw == null) return null;
        String s = raw.trim().replace('\\','/');
        if (s.isEmpty()) return null;
        if (s.startsWith("http://") || s.startsWith("https://")) return s;

        s = s.replaceFirst("^/+","");               // ตัด / นำหน้า
        if (s.startsWith("uploads/")) s = s.substring(8);
        if (s.startsWith("resources/uploads/")) s = s.substring("resources/uploads/".length());
        return s;
    }

    private static void addIfPresent(List<String> out, String normalized) {
        if (normalized != null && !normalized.isBlank() && !out.contains(normalized)) out.add(normalized);
    }
}
