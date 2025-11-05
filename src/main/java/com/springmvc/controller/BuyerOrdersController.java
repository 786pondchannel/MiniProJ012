	package com.springmvc.controller;
	
	import com.springmvc.model.HibernateConnection;
	import com.springmvc.model.Member;
	import com.springmvc.service.OrderService;
	import jakarta.servlet.ServletOutputStream;
	import jakarta.servlet.http.HttpServletResponse;
	import jakarta.servlet.http.HttpSession;
	import org.hibernate.Session;
	import org.hibernate.query.NativeQuery;
	import org.springframework.beans.factory.annotation.Autowired;
	import org.springframework.http.MediaType;
	import org.springframework.http.ResponseEntity;
	import org.springframework.stereotype.Controller;
	import org.springframework.ui.Model;
	import org.springframework.web.bind.annotation.*;
	import org.springframework.web.multipart.MultipartFile;
	import org.springframework.web.servlet.mvc.support.RedirectAttributes;
	
	import java.io.InputStream;
	import java.nio.file.*;
	import java.util.*;
	
	/**
	 * Controller สำหรับหน้า "คำสั่งซื้อของฉัน" (MyOrders.jsp)
	 *
	 * Endpoints หลัก:
	 *  GET  /orders                             -> ตารางคำสั่งซื้อ
	 *  POST /orders/{orderId}/upload-receipt    -> อัปโหลดสลิป
	 *  GET  /orders/{orderId}/receipt           -> JSON {url:"..."}
	 *  GET  /orders/{orderId}/receipt/image     -> stream สลิป
	 *  GET  /orders/{orderId}/payment-qr        -> JSON {url:"..."} QR ร้าน
	 *  GET  /orders/{orderId}/payment-qr/image  -> stream QR ร้าน
	 *  POST /orders/{orderId}/quick             -> แชท Quick Action (demo)
	 *  POST /orders/{orderId}/cancel            -> ยกเลิก (ฟอร์ม HTML) => redirect:/orders
	 *  POST /orders/{orderId}/cancel.json       -> ยกเลิก (AJAX/JSON)
	 */
	@Controller
	@RequestMapping("/orders")
	public class BuyerOrdersController {
	
	    private static final Path RECEIPTS_DIR   = Paths.get("D:/Toos/png/receipts");
	    private static final Path FARMER_QR_ROOT = Paths.get("D:/Toos/png/slip");
	
	    @Autowired
	    private OrderService orderService;
	
	    /* ========================= Utilities ========================= */
	
	    private static String esc(String s){
	        if(s==null) return "";
	        return s.replace("\\","\\\\")
	                .replace("\"","\\\"")
	                .replace("\r","\\r")
	                .replace("\n","\\n");
	    }
	    private static long nowEpoch(){ return System.currentTimeMillis(); }
	
	    private Optional<Object[]> fetchRow(Session s, String sql, Map<String, Object> params){
	        NativeQuery<?> q = s.createNativeQuery(sql);
	        params.forEach(q::setParameter);
	        @SuppressWarnings("unchecked")
	        List<Object[]> list = (List<Object[]>) q.list();
	        if(list==null || list.isEmpty()) return Optional.empty();
	        return Optional.of(list.get(0));
	    }
	    private Optional<Object> fetchScalar(Session s, String sql, Map<String, Object> params){
	        NativeQuery<?> q = s.createNativeQuery(sql);
	        params.forEach(q::setParameter);
	        List<?> list = q.list();
	        if(list==null || list.isEmpty()) return Optional.empty();
	        return Optional.ofNullable(list.get(0));
	    }
	
	    /** map ค่า Img จาก DB -> ไฟล์จริงในดิสก์ */
	    private Path resolveReceiptPath(String img){
	        if(img==null) return null;
	        String clean = img.trim().replace("\\","/");
	
	        // absolute?
	        if (clean.matches("^[a-zA-Z]:/.*") || clean.startsWith("/")) {
	            Path p = Paths.get(clean);
	            if (Files.isRegularFile(p)) return p;
	            String noLead = clean.replaceAll("^/+","");
	            Path alt = Paths.get("D:/Toos/png").resolve(noLead).normalize();
	            if (Files.isRegularFile(alt)) return alt;
	        }
	
	        // relative → receipts/*
	        clean = clean.replaceFirst("^/?uploads/receipts/","")
	                     .replaceFirst("^/?receipts/","");
	
	        Path p1 = Paths.get("D:/Toos/png/receipts").resolve(clean).normalize();
	        if (Files.isRegularFile(p1)) return p1;
	
	        Path p2 = Paths.get("D:/Toos/png").resolve("receipts").resolve(clean).normalize();
	        return Files.isRegularFile(p2) ? p2 : null;
	    }
	
	    /* ========================= Pages ========================= */
	
	    @GetMapping
	    public String list(HttpSession session, Model model) {
	        Member current = (Member) session.getAttribute("loggedInUser");
	        if (current == null) return "redirect:/login";
	
	        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
	            @SuppressWarnings("unchecked")
	            List<Object[]> rows = s.createNativeQuery("""
	                SELECT orderId, orderDate, totalPrice, orderStatus, paymentStatus, farmerId
	                  FROM perorder
	                 WHERE memberId = :mid
	                 ORDER BY orderDate DESC
	            """).setParameter("mid", current.getMemberId()).list();
	
	            model.addAttribute("orders", rows);
	        }
	        return "MyOrders";
	    }
	
	    /* ========================= Upload slip ========================= */
	
	    @PostMapping("/{orderId}/upload-receipt")
	    public String uploadReceipt(@PathVariable String orderId,
	                                @RequestParam(value = "file", required = false) MultipartFile file,
	                                @RequestParam(value = "reference", required = false) String ref,
	                                HttpSession session,
	                                RedirectAttributes ra) {
	        Member current = (Member) session.getAttribute("loggedInUser");
	        if (current == null) return "redirect:/login";
	
	        if (file == null || file.isEmpty()) {
	            ra.addFlashAttribute("error", "กรุณาเลือกไฟล์สลิปก่อนอัปโหลด");
	            return "redirect:/orders";
	        }
	
	        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
	            Optional<Object[]> rowOpt = fetchRow(s, """
	                SELECT orderStatus, paymentStatus
	                  FROM perorder
	                 WHERE orderId = :oid AND memberId = :mid
	            """, Map.of("oid", orderId, "mid", current.getMemberId()));
	
	            if (rowOpt.isEmpty()) {
	                ra.addFlashAttribute("error", "ไม่พบคำสั่งซื้อของคุณ");
	                return "redirect:/orders";
	            }
	            Object[] row = rowOpt.get();
	            String orderStatus   = row[0] == null ? "" : row[0].toString();
	            String paymentStatus = row[1] == null ? "" : row[1].toString();
	
	            if (!"FARMER_CONFIRMED".equalsIgnoreCase(orderStatus)
	                    || !"AWAITING_BUYER_PAYMENT".equalsIgnoreCase(paymentStatus)) {
	                ra.addFlashAttribute("error", "อัปโหลดสลิปได้เฉพาะออเดอร์ที่ 'ร้านยืนยันแล้ว' และ 'ยังไม่ชำระ'");
	                return "redirect:/orders";
	            }
	
	            Files.createDirectories(RECEIPTS_DIR);
	            String orig = file.getOriginalFilename();
	            String ext = ".jpg";
	            if (orig != null) {
	                String low = orig.toLowerCase(Locale.ROOT);
	                if (low.endsWith(".png"))      ext = ".png";
	                else if (low.endsWith(".jpeg"))ext = ".jpeg";
	                else if (low.endsWith(".webp"))ext = ".webp";
	                else if (low.endsWith(".jpg")) ext = ".jpg";
	            }
	            String filename = UUID.randomUUID().toString() + ext;
	            Path dest = RECEIPTS_DIR.resolve(filename).normalize();
	            file.transferTo(dest.toFile());
	
	            String imgRel = "receipts/" + filename;
	
	            s.beginTransaction();
	            s.createNativeQuery("""
	                INSERT INTO receipt(receiptId, ReferenceID, Img, perorder_orderId)
	                VALUES (:rid, :ref, :img, :oid)
	            """)
	            .setParameter("rid", UUID.randomUUID().toString())
	            .setParameter("ref", (ref==null || ref.isBlank()) ? null : ref.trim())
	            .setParameter("img", imgRel)
	            .setParameter("oid", orderId)
	            .executeUpdate();
	
	            s.createNativeQuery("""
	                UPDATE perorder
	                   SET paymentStatus = :p, updatedAt = NOW()
	                 WHERE orderId = :oid
	            """)
	            .setParameter("p", "PAID_PENDING_VERIFY")
	            .setParameter("oid", orderId)
	            .executeUpdate();
	
	            s.getTransaction().commit();
	
	            ra.addFlashAttribute("msg", "อัปโหลดสลิปสำเร็จ");
	            return "redirect:/orders?uploaded=" + orderId;
	        } catch (Exception e) {
	            ra.addFlashAttribute("error", "อัปโหลดไม่สำเร็จ: " + e.getMessage());
	            return "redirect:/orders";
	        }
	    }
	
	    /* ========================= Receipt JSON + Image ========================= */
	
	    @GetMapping(value="/{orderId}/receipt", produces="application/json; charset=UTF-8")
	    @ResponseBody
	    public ResponseEntity<String> getReceiptJson(@PathVariable String orderId, HttpSession session){
	        Member current = (Member) session.getAttribute("loggedInUser");
	        if (current == null)
	            return ResponseEntity.status(401).body("{\"url\":null,\"message\":\"unauthorized\"}");
	
	        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
	            Optional<Object> ok = fetchScalar(s,
	                    "SELECT 1 FROM perorder WHERE orderId=:oid AND memberId=:mid",
	                    Map.of("oid", orderId, "mid", current.getMemberId()));
	            if (ok.isEmpty())
	                return ResponseEntity.status(403).body("{\"url\":null,\"message\":\"forbidden\"}");
	
	            Optional<Object> imgOpt = fetchScalar(s, """
	                SELECT Img
	                  FROM receipt
	                 WHERE perorder_orderId = :oid
	                 ORDER BY receiptId DESC
	                 LIMIT 1
	            """, Map.of("oid", orderId));
	
	            if (imgOpt.isEmpty() || imgOpt.get()==null)
	                return ResponseEntity.ok("{\"url\":null}");
	
	            String imgRaw = String.valueOf(imgOpt.get()).trim();
	            Path file = resolveReceiptPath(imgRaw);
	
	            if (file != null && Files.isRegularFile(file)) {
	                String imgClean = imgRaw.replace("\\","/").replaceAll("^/+","");
	                if (!imgClean.startsWith("uploads/")) imgClean = "uploads/" + imgClean;
	                String staticUrl = "/" + imgClean;
	                return ResponseEntity.ok("{\"url\":\"" + esc(staticUrl) + "\"}");
	            }
	
	            String url = "/orders/" + esc(orderId) + "/receipt/image?ts=" + nowEpoch();
	            return ResponseEntity.ok("{\"url\":\"" + esc(url) + "\"}");
	        } catch (Exception e) {
	            return ResponseEntity.status(500).body("{\"url\":null}");
	        }
	    }
	
	    @GetMapping("/{orderId}/receipt/image")
	    public void getReceiptImage(@PathVariable String orderId,
	                                HttpSession session,
	                                HttpServletResponse resp) {
	        Member current = (Member) session.getAttribute("loggedInUser");
	        if (current == null) { resp.setStatus(401); return; }
	
	        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
	            Optional<Object> ok = fetchScalar(s,
	                    "SELECT 1 FROM perorder WHERE orderId=:oid AND memberId=:mid",
	                    Map.of("oid", orderId, "mid", current.getMemberId()));
	            if (ok.isEmpty()) { resp.setStatus(403); return; }
	
	            Optional<Object> imgOpt = fetchScalar(s, """
	                SELECT Img
	                  FROM receipt
	                 WHERE perorder_orderId = :oid
	                 ORDER BY receiptId DESC
	                 LIMIT 1
	            """, Map.of("oid", orderId));
	
	            if (imgOpt.isEmpty() || imgOpt.get()==null) { resp.setStatus(404); return; }
	
	            String imgRaw = String.valueOf(imgOpt.get()).trim();
	            Path file = resolveReceiptPath(imgRaw);
	
	            if (file==null || !Files.isRegularFile(file)) { resp.setStatus(404); return; }
	
	            String ct = Files.probeContentType(file);
	            if (ct==null) ct = MediaType.IMAGE_PNG_VALUE;
	            resp.setContentType(ct);
	            resp.setHeader("Cache-Control","no-store, no-cache, must-revalidate, max-age=0");
	            resp.setHeader("Pragma","no-cache");
	            try (ServletOutputStream os = resp.getOutputStream();
	                 InputStream in = Files.newInputStream(file, StandardOpenOption.READ)) {
	                in.transferTo(os);
	            }
	        } catch (Exception e) {
	            resp.setStatus(500);
	        }
	    }
	
	    /* ========================= Farmer QR ========================= */
	
	    @GetMapping(value="/{orderId}/payment-qr", produces="application/json; charset=UTF-8")
	    @ResponseBody
	    public ResponseEntity<String> getFarmerQrJson(@PathVariable String orderId, HttpSession session){
	        Member current = (Member) session.getAttribute("loggedInUser");
	        if (current == null)
	            return ResponseEntity.status(401).body("{\"url\":null,\"message\":\"unauthorized\"}");
	
	        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
	            Optional<Object> farmerIdOpt = fetchScalar(s, """
	                SELECT farmerId
	                  FROM perorder
	                 WHERE orderId = :oid AND memberId = :mid
	            """, Map.of("oid", orderId, "mid", current.getMemberId()));
	
	            if (farmerIdOpt.isEmpty())
	                return ResponseEntity.status(403).body("{\"url\":null,\"message\":\"forbidden\"}");
	
	            String farmerId = String.valueOf(farmerIdOpt.get());
	            Path dir = FARMER_QR_ROOT.resolve(farmerId);
	            try (var st = Files.list(dir)) {
	                Optional<Path> any = st.filter(Files::isRegularFile).findFirst();
	                if (any.isEmpty()) return ResponseEntity.ok("{\"url\":null}");
	            } catch (Exception e) {
	                return ResponseEntity.ok("{\"url\":null}");
	            }
	
	            String url = "/orders/" + esc(orderId) + "/payment-qr/image?ts=" + nowEpoch();
	            return ResponseEntity.ok("{\"url\":\"" + esc(url) + "\"}");
	        }
	    }
	
	    @GetMapping("/{orderId}/payment-qr/image")
	    public void getFarmerQrImage(@PathVariable String orderId,
	                                 HttpSession session,
	                                 HttpServletResponse resp) {
	        Member current = (Member) session.getAttribute("loggedInUser");
	        if (current == null) { resp.setStatus(401); return; }
	
	        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
	            Object fid = s.createNativeQuery("""
	                SELECT farmerId
	                  FROM perorder
	                 WHERE orderId = :oid AND memberId = :mid
	            """).setParameter("oid", orderId)
	              .setParameter("mid", current.getMemberId())
	              .uniqueResult();
	            if (fid == null) { resp.setStatus(403); return; }
	
	            Path dir = FARMER_QR_ROOT.resolve(String.valueOf(fid));
	            Path file = null;
	            try (var st = Files.list(dir)) {
	                Optional<Path> any = st.filter(Files::isRegularFile).findFirst();
	                if (any.isPresent()) file = any.get();
	            } catch (Exception ignore) { }
	            if (file==null) { resp.setStatus(404); return; }
	
	            String ct = Files.probeContentType(file);
	            if (ct==null) ct = MediaType.IMAGE_PNG_VALUE;
	
	            resp.setContentType(ct);
	            resp.setHeader("Cache-Control","no-store, no-cache, must-revalidate, max-age=0");
	            resp.setHeader("Pragma","no-cache");
	            try (ServletOutputStream os = resp.getOutputStream();
	                 InputStream in = Files.newInputStream(file, StandardOpenOption.READ)) {
	                in.transferTo(os);
	            }
	        } catch (Exception e) {
	            resp.setStatus(500);
	        }
	    }
	
	    /* ========================= Quick Chat (demo) ========================= */
	
	    @PostMapping(value="/{orderId}/quick", consumes="application/x-www-form-urlencoded", produces="application/json; charset=UTF-8")
	    @ResponseBody
	    public ResponseEntity<String> quick(@PathVariable String orderId,
	                                        @RequestParam("action") String action,
	                                        HttpSession session){
	        Member current = (Member) session.getAttribute("loggedInUser");
	        if (current == null)
	            return ResponseEntity.status(401).body("[]");
	
	        String a = action==null ? "" : action.trim().toUpperCase(Locale.ROOT);
	        long now = nowEpoch();
	
	        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
	            Optional<Object[]> rowOpt = fetchRow(s, """
	                SELECT orderStatus, paymentStatus, farmerId
	                  FROM perorder
	                 WHERE orderId = :oid AND memberId = :mid
	            """, Map.of("oid", orderId, "mid", current.getMemberId()));
	            if (rowOpt.isEmpty()) return ResponseEntity.ok("[]");
	
	            Object[] row = rowOpt.get();
	            String ost = String.valueOf(row[0]);
	            String pst = String.valueOf(row[1]);
	            String farmerId = String.valueOf(row[2]);
	
	            List<String> out = new ArrayList<>();
	
	            switch (a){
	                case "ORDER_STATUS" -> {
	                    String msg = "สถานะปัจจุบันจากตาราง\n" +
	                            "• ORDER: " + ost + "\n" +
	                            "• PAYMENT: " + pst;
	                    out.add("{\"senderRole\":\"SYSTEM\",\"type\":\"ORDER_STATUS\",\"title\":\"สถานะคำสั่งซื้อ\",\"message\":\""+esc(msg)+"\",\"createdAt\":"+now+"}");
	                }
	                case "STORE_CONTACT" -> {
	                    String msg = "ข้อมูลติดต่อร้าน (ตัวอย่าง)\nโทร: 081-234-5678\nอีเมล: farm@example.com";
	                    out.add("{\"senderRole\":\"FARMER\",\"type\":\"STORE_CONTACT\",\"title\":\"ข้อมูลติดต่อร้าน\",\"message\":\""+esc(msg)+"\",\"createdAt\":"+now+"}");
	                }
	                case "STORE_ADDRESS" -> {
	                    String msg = "เลขที่ 99 หมู่ 9 ต.บางนา อ.เมือง\nจ.กรุงเทพฯ 10260";
	                    out.add("{\"senderRole\":\"FARMER\",\"type\":\"STORE_ADDRESS\",\"title\":\"ที่อยู่ฟาร์ม\",\"message\":\""+esc(msg)+"\",\"createdAt\":"+now+"}");
	                }
	                case "REQUEST_PAYMENT_QR", "REQUEST_PAYMENT" -> {
	                    String imageUrl = "/orders/" + esc(orderId) + "/payment-qr/image?ts=" + now;
	                    String msg = "สแกน QR เพื่อโอนเข้าบัญชีได้เลย";
	                    out.add("{\"senderRole\":\"FARMER\",\"type\":\"REQUEST_PAYMENT_QR\",\"title\":\"ชำระเงินด้วย QR\",\"message\":\""+esc(msg)+"\",\"imageUrl\":\""+esc(imageUrl)+"\",\"createdAt\":"+now+"}");
	                }
	                case "HOW_TO_UPLOAD" -> {
	                    String msg = "ไปที่แถวของออเดอร์ > ช่อง \"อัปโหลดสลิป\" แล้วเลือกไฟล์ภาพ";
	                    out.add("{\"senderRole\":\"SYSTEM\",\"type\":\"HOW_TO_UPLOAD\",\"title\":\"วิธีอัปโหลดสลิป\",\"message\":\""+esc(msg)+"\",\"createdAt\":"+now+"}");
	                }
	                default -> { }
	            }
	
	            String json = "[" + String.join(",", out) + "]";
	            return ResponseEntity.ok()
	                    .header("Cache-Control","no-store, no-cache, must-revalidate, max-age=0")
	                    .header("Pragma","no-cache")
	                    .body(json);
	        }
	    }
	
	    /* ========================= ยกเลิกคำสั่งซื้อ =========================
	       แยก 2 เส้นทางชัดเจน เพื่อเลี่ยง 406 และให้รีเฟรชหน้าได้ทันที
	       - /{orderId}/cancel      : ฟอร์ม HTML -> redirect:/orders
	       - /{orderId}/cancel.json : AJAX/JSON
	    ===================================================================== */
	
	    // ฟอร์ม HTML: เบราว์เซอร์จะรับ redirect แล้วโหลดหน้า /orders ใหม่ (เหมือนรีเฟรช)
	    @PostMapping(
	        value = "/{orderId}/cancel",
	        consumes = MediaType.APPLICATION_FORM_URLENCODED_VALUE
	    )
	    public String cancelOrderHtml(@PathVariable String orderId,
	                                  HttpSession session,
	                                  RedirectAttributes ra) {
	        Member current = (Member) session.getAttribute("loggedInUser");
	        if (current == null) return "redirect:/login";
	
	        boolean ok = orderService.cancelByBuyer(orderId, current.getMemberId());
	        if (ok) {
	            ra.addFlashAttribute("msg", "ยกเลิกและลบออเดอร์เรียบร้อย");
	        } else {
	            ra.addFlashAttribute("error", "ยกเลิกไม่ได้ในขั้นตอนนี้ หรือไม่ใช่เจ้าของออเดอร์");
	        }
	        return "redirect:/orders"; // โหลดใหม่ทั้งหน้า
	    }
	
	    // AJAX/JSON: ใช้ได้เมื่อเรียกด้วย fetch() ฝั่ง JS (ถ้าต้องการ)
	    @PostMapping(
	        value = "/{orderId}/cancel.json",
	        produces = MediaType.APPLICATION_JSON_VALUE
	    )
	    @ResponseBody
	    public Map<String, Object> cancelOrderJson(@PathVariable String orderId,
	                                               HttpSession session) {
	        Member current = (Member) session.getAttribute("loggedInUser");
	        if (current == null) {
	            return Map.of("ok", false, "reason", "unauthorized");
	        }
	        boolean ok = orderService.cancelByBuyer(orderId, current.getMemberId());
	        return ok ? Map.of("ok", true) : Map.of("ok", false, "reason", "cannot_cancel");
	    }
	}
