package com.springmvc.controller;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletContext;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.lang.reflect.Method;
import java.util.*;

@Controller
@RequestMapping("/farmer")
public class FarmerProfileViewController {

    // ชี้ไฟล์ JSP ตรงๆ (สะกดชื่อ/ตำแหน่งให้ตรงโปรเจค)
    private static final String JSP_PATH = "/WEB-INF/jsp/FarmerProfile.jsp";

    @Autowired(required = false) private Object farmerService;
    @Autowired(required = false) private Object orderService;
    @Autowired(required = false) private ServletContext servletContext;

    /* ===== Debug endpoints (ไว้เช็คว่า controller วิ่ง) ===== */
    @GetMapping("/profile/view/ping")
    @ResponseBody
    public String ping() { return "OK: FarmerProfileViewController is alive"; }

    @GetMapping(value="/profile/view/raw", produces="text/html; charset=UTF-8")
    @ResponseBody
    public String raw(@RequestParam String farmerId, HttpSession session){
        Object farmer = getFarmer(farmerId);
        int cartCount = toInt(tryInvoke(orderService, new String[]{
            "computeCartCount","getCartCount","cartCount","countCart"
        }, new Class[]{HttpSession.class}, session), 0);

        return "<h3>RAW VIEW</h3>"
             + "<div>farmerId = " + farmerId + "</div>"
             + "<div>farmer = " + (farmer==null? "(null)" : farmer.toString()) + "</div>"
             + "<div>cartCount = " + cartCount + "</div>";
    }

    /* ===== ของจริง: เสิร์ฟ JSP + มี fallback กันหน้าขาว ===== */
    @GetMapping("/profile/view")
    public void profile(@RequestParam(name="farmerId", required=false) String farmerId,
                        Model model,
                        HttpSession session,
                        HttpServletRequest request,
                        HttpServletResponse response) throws IOException {

        // กัน cache ทุกด่าน (เบราว์เซอร์/พร็อกซี่) ที่อาจจำ “หน้าเปล่า”
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
        response.addHeader("Cache-Control", "post-check=0, pre-check=0");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        // เติมค่าเริ่มต้นไว้ก่อน กัน JSP เจอ null แล้วไม่ render
        seedDefaults(model);

        // ตรวจพารามิเตอร์
        if (farmerId == null || farmerId.isBlank()) {
            model.addAttribute("error", "farmerId ว่างหรือไม่ถูกต้อง");
            safeForward(request, response, model);
            return;
        }

        // cartCount (ถ้ามีเมธอดใดเมธอดหนึ่ง)
        tryInvokeToModel(orderService, model, "cartCount", new String[]{
            "computeCartCount","getCartCount","cartCount","countCart"
        }, new Class[]{HttpSession.class}, session, 0);

        // farmer
        Object farmer = getFarmer(farmerId);
        if (farmer == null) {
            model.addAttribute("error", "ไม่พบร้าน/เกษตรกรที่ต้องการดูข้อมูล");
            safeForward(request, response, model);
            return;
        }
        model.addAttribute("farmer", farmer);

        // products
        List<?> products = toList(tryInvoke(farmerService, new String[]{
            "listProductsByFarmer","getProductsOfFarmer","getProductsByFarmerId",
            "findProductsByFarmer","findProductsByFarmerId","productsByFarmer"
        }, new Class[]{String.class}, farmerId));
        model.addAttribute("products", products != null ? products : Collections.emptyList());

        // reviews
        List<?> reviews = toList(tryInvoke(farmerService, new String[]{
            "listReviewsByFarmer","getReviewsByFarmerId","getReviews",
            "findReviewsByFarmer","reviewsOfFarmer"
        }, new Class[]{String.class}, farmerId));
        model.addAttribute("reviews", reviews != null ? reviews : Collections.emptyList());

        // reviewCount
        Integer reviewCount = toInt(tryInvoke(farmerService, new String[]{
            "countReviewsByFarmer","getReviewCount","countReviews","countReviewsByFarmerId"
        }, new Class[]{String.class}, farmerId), 0);
        model.addAttribute("reviewCount", reviewCount);

        // avgRating
        Double avgRating = toDouble(tryInvoke(farmerService, new String[]{
            "avgRatingByFarmer","getAvgRating","averageRatingByFarmer","getAverageRating"
        }, new Class[]{String.class}, farmerId), 0.0);
        model.addAttribute("avgRating", avgRating);

        // gallery (ถ้ามี)
        List<?> gallery = toList(tryInvoke(farmerService, new String[]{
            "getGalleryByFarmerId","listGalleryByFarmer","getFarmerGallery","galleryOfFarmer"
        }, new Class[]{String.class}, farmerId));
        model.addAttribute("gallery", gallery != null ? gallery : Collections.emptyList());

        // paymentSlipUrl (มาจาก service หรือจาก field ใน farmer)
        Object slipUrl = tryInvoke(farmerService, new String[]{
            "getPaymentSlipUrl","getPaymentQRUrl","getQrImageUrl","getQrUrl"
        }, new Class[]{String.class}, farmerId);
        if (slipUrl == null && farmer != null) {
            slipUrl = readProperty(farmer, "paymentSlipUrl");
            if (slipUrl == null) slipUrl = readProperty(farmer, "paymentQRUrl");
            if (slipUrl == null) slipUrl = readProperty(farmer, "qrImage");
            if (slipUrl == null) slipUrl = readProperty(farmer, "qrUrl");
        }
        model.addAttribute("paymentSlipUrl", slipUrl);

        // ยิง JSP แบบแมนนวล; ถ้า fail จะเขียน fallback HTML ทันที (ไม่ปล่อยขาว)
        safeForward(request, response, model);
    }

    /* ===================== forward + fallback ===================== */
    private void safeForward(HttpServletRequest req, HttpServletResponse resp, Model model) throws IOException {
        // เอา attribute ทั้งหมดลง request (JSP ใช้ request-scope)
        for (Map.Entry<String,Object> e : model.asMap().entrySet()) {
            req.setAttribute(e.getKey(), e.getValue());
        }

        try {
            // เช็คไฟล์ JSP มีจริงไหม (กันพลาด path)
            if (servletContext != null && servletContext.getResource(JSP_PATH) == null) {
                writeFallback(resp, 500,
                    "<h2>JSP ไม่พบไฟล์</h2><div>path: <code>" + JSP_PATH + "</code></div>");
                return;
            }

            RequestDispatcher rd = req.getRequestDispatcher(JSP_PATH);
            rd.forward(req, resp);
        } catch (Throwable ex) {
            // เขียน fallback ออกทันที + โชว์ข้อมูลหลักเพื่อดีบัก
            StringBuilder sb = new StringBuilder(2048);
            sb.append("<h2>Fallback: เรนเดอร์ JSP ล้มเหลว</h2>")
              .append("<div style='color:#b91c1c'>").append(escape(ex.toString())).append("</div>")
              .append("<hr>")
              .append("<h3>ข้อมูลใน model</h3><pre style='white-space:pre-wrap'>")
              .append(escape(model.asMap().toString()))
              .append("</pre>")
              .append("<div>JSP: <code>").append(JSP_PATH).append("</code></div>");
            writeFallback(resp, 500, sb.toString());
        }
    }

    private void writeFallback(HttpServletResponse resp, int status, String html) throws IOException {
        resp.setStatus(status);
        resp.setContentType("text/html; charset=UTF-8");
        try (PrintWriter w = resp.getWriter()) {
            w.write("<!doctype html><meta charset='utf-8'>"
                  + "<title>FarmerProfile (Fallback)</title>"
                  + "<div style='font-family:system-ui,Segoe UI,Roboto,Arial;padding:16px'>"
                  + html + "</div>");
            w.flush();
        }
        resp.flushBuffer(); // บังคับส่ง ไม่ปล่อยหน้าขาว
    }

    private static String escape(String s){ return s==null? "": s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;"); }

    /* ===================== helpers ===================== */
    private Object getFarmer(String farmerId) {
        Object farmer = tryInvoke(farmerService, new String[]{
            "getFarmerById","findById","getById","findFarmerById",
            "getFarmer","loadFarmer","findOne"
        }, new Class[]{String.class}, farmerId);
        if (farmer instanceof Optional) farmer = ((Optional<?>) farmer).orElse(null);
        return farmer;
    }

    private void seedDefaults(Model model) {
        if (!model.containsAttribute("products"))       model.addAttribute("products", Collections.emptyList());
        if (!model.containsAttribute("reviews"))        model.addAttribute("reviews", Collections.emptyList());
        if (!model.containsAttribute("reviewCount"))    model.addAttribute("reviewCount", 0);
        if (!model.containsAttribute("avgRating"))      model.addAttribute("avgRating", 0.0);
        if (!model.containsAttribute("gallery"))        model.addAttribute("gallery", Collections.emptyList());
        if (!model.containsAttribute("paymentSlipUrl")) model.addAttribute("paymentSlipUrl", null);
        if (!model.containsAttribute("cartCount"))      model.addAttribute("cartCount", 0);
    }

    private Object tryInvoke(Object target, String[] names, Class<?>[] types, Object... args) {
        if (target == null) return null;
        Class<?> c = target.getClass();
        for (String n : names) {
            try {
                Method m = c.getMethod(n, types);
                m.setAccessible(true);
                return m.invoke(target, args);
            } catch (NoSuchMethodException ignore) {
            } catch (Exception ex) {
                return null;
            }
        }
        return null;
    }

    private void tryInvokeToModel(Object target, Model model, String attr,
                                  String[] names, Class<?>[] types, Object arg, Object defVal) {
        Object val = tryInvoke(target, names, types, arg);
        model.addAttribute(attr, val != null ? val : defVal);
    }

    private List<?> toList(Object o) {
        if (o == null) return null;
        if (o instanceof List) return (List<?>) o;
        if (o instanceof Collection) return new ArrayList<>((Collection<?>) o);
        if (o.getClass().isArray()) {
            int len = java.lang.reflect.Array.getLength(o);
            List<Object> list = new ArrayList<>(len);
            for (int i = 0; i < len; i++) list.add(java.lang.reflect.Array.get(o, i));
            return list;
        }
        return Collections.singletonList(o);
    }

    private Integer toInt(Object o, int def) {
        if (o == null) return def;
        if (o instanceof Number) return ((Number) o).intValue();
        try { return Integer.parseInt(String.valueOf(o)); } catch (Exception e) { return def; }
    }

    private Double toDouble(Object o, double def) {
        if (o == null) return def;
        if (o instanceof Number) return ((Number) o).doubleValue();
        try { return Double.parseDouble(String.valueOf(o)); } catch (Exception e) { return def; }
    }

    private Object readProperty(Object bean, String name) {
        try {
            String getter = "get" + Character.toUpperCase(name.charAt(0)) + name.substring(1);
            Method m = bean.getClass().getMethod(getter);
            return m.invoke(bean);
        } catch (Exception ignore) {}
        try {
            var f = bean.getClass().getDeclaredField(name);
            f.setAccessible(true);
            return f.get(bean);
        } catch (Exception ignore) {}
        if (bean instanceof Map) return ((Map<?, ?>) bean).get(name);
        return null;
    }
}
