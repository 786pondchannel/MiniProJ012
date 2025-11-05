package com.springmvc.controller;

import com.springmvc.model.Farmer;
import com.springmvc.model.FarmerImage;
import com.springmvc.service.FarmerImageService;
import jakarta.servlet.ServletContext;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.util.ReflectionUtils;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.lang.reflect.Method;
import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Controller
@RequestMapping("/farmer/profile")
public class FarmerImageController {

    @Autowired private FarmerImageService imageService;
    @Autowired private ServletContext servletContext;

    /** ตั้ง session.farmerId อย่างไวเพื่อสลับฟาร์ม */
    @GetMapping("/as/{farmerId}")
    public String impersonate(@PathVariable String farmerId, HttpSession session) {
        if (StringUtils.hasText(farmerId)) {
            session.setAttribute("farmerId", farmerId.trim());
        }
        return "redirect:/farmer/profile/edit";
    }

    /** GET: หน้าแก้ไข (โหลดข้อมูลสดจากฐานข้อมูลทุกครั้ง) */
    @GetMapping("/edit")
    public String edit(@RequestParam(value = "farmerId", required = false) String farmerIdParam,
                       HttpSession session,
                       Model model) {
        String farmerId = resolveFarmerId(session, farmerIdParam);
        if (!StringUtils.hasText(farmerId)) {
            model.addAttribute("error",
                    "✖ ไม่พบรหัสฟาร์ม (ไปที่ /farmer/profile/as/{farmerId} หรือแนบ ?farmerId= ในลิงก์)");
            return "EditFarmerProfile";
        }

        Farmer farmer = imageService.findFarmerById(farmerId);   // โหลดสด
        if (farmer == null) {
            model.addAttribute("error", "✖ ไม่พบฟาร์ม: " + farmerId);
            return "EditFarmerProfile";
        }

        List<FarmerImage> gallery = imageService.findGallery(farmerId); // โหลดสด
        model.addAttribute("farmer", farmer);
        model.addAttribute("farmerImages", gallery);
        return "EditFarmerProfile";
    }

    /** POST: บันทึก (PRG + refresh session) */
    @PostMapping("/edit")
    public String save(
            Farmer farmer,                       // form binding เฉพาะฟิลด์ที่อนุญาต
            HttpSession session,

            @RequestParam(value = "farmImage",  required = false) MultipartFile farmImage,
            @RequestParam(value = "slipImage",  required = false) MultipartFile slipImage,

            @RequestParam(value = "galleryFiles",  required = false) MultipartFile[] galleryFiles,
            @RequestParam(value = "deleteImageIds", required = false) List<Long> deleteIds,
            @RequestParam(value = "sortImageIds",   required = false) String sortCsv,

            @RequestParam(value = "confirmPassword", required = false) String confirmPassword,

            RedirectAttributes ra
    ) {
        // อ่าน farmerId ฝั่งเซิร์ฟเวอร์เท่านั้น
        String rawId = resolveFarmerId(session, null);
        if (!StringUtils.hasText(rawId)) {
            ra.addFlashAttribute("error", "✖ ไม่พบรหัสฟาร์ม");
            return "redirect:/farmer/profile/edit";
        }
        String farmerId = sanitizeId(rawId);

        // โหลดของเดิมเพื่อ merge
        Farmer current = imageService.findFarmerById(farmerId);
        if (current == null) {
            ra.addFlashAttribute("error", "✖ ไม่พบฟาร์ม: " + farmerId);
            return "redirect:/farmer/profile/edit";
        }

        // ===== Validation ฝั่งเซิร์ฟเวอร์ =====
        Map<String, String> fe = new LinkedHashMap<>();
        String farmName = safe(farmer.getFarmName());
        String email    = safe(farmer.getEmail());
        String phone    = safeDigits(farmer.getPhoneNumber());
        String address  = safe(farmer.getAddress());
        String farmLoc  = safe(farmer.getFarmLocation());
        String pwd      = safe(farmer.getPassword());

        if (!StringUtils.hasText(farmName)) fe.put("farmName", "กรอกชื่อฟาร์ม");
        if (StringUtils.hasText(email) && !email.contains("@")) fe.put("email", "อีเมลไม่ถูกต้อง");
        if (StringUtils.hasText(phone) && !phone.matches("^0\\d{9}$")) fe.put("phoneNumber","ใส่เบอร์ให้ถูกต้อง 10 หลัก");
        if (!StringUtils.hasText(address)) fe.put("address","กรุณากรอกที่อยู่");
        if (!StringUtils.hasText(farmLoc)) fe.put("farmLocation","กรุณากรอกที่ตั้งฟาร์ม");

        if (StringUtils.hasText(pwd)) {
            if (pwd.length() < 8) fe.put("password", "อย่างน้อย 8 ตัวอักษร");
            if (confirmPassword == null || !pwd.equals(confirmPassword)) fe.put("confirmPassword", "ยืนยันรหัสผ่านไม่ตรงกัน");
        }

        if (!fe.isEmpty()) {
            ra.addFlashAttribute("error", "กรุณาแก้ไขข้อมูลที่ไฮไลต์สีแดง");
            return "redirect:/farmer/profile/edit";
        }

        // ===== Merge แล้วอัปเดตพื้นฐาน =====
        current.setFarmerId(farmerId);
        current.setFarmName(farmName);
        current.setEmail(email);
        current.setPhoneNumber(phone);
        current.setAddress(address);
        current.setFarmLocation(farmLoc);
        if (StringUtils.hasText(pwd)) {
            // TODO: ถ้ามี passwordEncoder ให้เข้ารหัสตรงนี้
            current.setPassword(pwd);
        }

        boolean baseChanged = imageService.updateFarmerBasicReturn(current); // << ใช้ตัวที่คืนค่าความเปลี่ยนแปลง

        // ===== อัปโหลดเดี่ยว (โปรไฟล์/สลิป) =====
        int touched = 0;
        try {
            if (farmImage != null && !farmImage.isEmpty()) {
                String path = imageService.saveProfileImage(farmerId, farmImage, servletContext);
                if (path != null) touched++;
            }
            if (slipImage != null && !slipImage.isEmpty()) {
                String path = imageService.saveSlipImage(farmerId, slipImage, servletContext);
                if (path != null) touched++;
            }
        } catch (RuntimeException ex) {
            ra.addFlashAttribute("error", ex.getMessage());
            return "redirect:/farmer/profile/edit";
        }

        // ===== ลบรูปเดิมตามที่ติ๊ก =====
        if (deleteIds != null && !deleteIds.isEmpty()) {
            touched += imageService.deleteGalleryByIdsCount(farmerId, deleteIds, true, servletContext);
        }

        // ===== เรียงรูปเดิมตาม sortCsv (เฉพาะรูปที่ยังไม่ถูกลบ) =====
        if (StringUtils.hasText(sortCsv)) {
            List<Long> ordered = Stream.of(sortCsv.split(","))
                    .map(String::trim).filter(s -> s.matches("\\d+"))
                    .map(Long::valueOf).collect(Collectors.toList());
            if (!ordered.isEmpty()) touched += imageService.reorderKeptImagesCount(farmerId, ordered);
        }

        // ===== อัปโหลดหลายรูป (gallery) สูงสุด 10 =====
        if (galleryFiles != null && galleryFiles.length > 0) {
            List<MultipartFile> list = Arrays.stream(galleryFiles)
                    .filter(Objects::nonNull).filter(fx -> !fx.isEmpty()).collect(Collectors.toList());
            if (!list.isEmpty()) {
                int currentCount = imageService.countGallery(farmerId);
                int canAdd = Math.max(0, 10 - currentCount);
                if (canAdd <= 0) {
                    ra.addFlashAttribute("error", "มีรูปครบ 10 แล้ว ลบรูปเดิมก่อน");
                    return "redirect:/farmer/profile/edit";
                }
                if (list.size() > canAdd) list = list.subList(0, canAdd);
                touched += imageService.saveNewGalleryImagesCount(farmerId, list, servletContext);
            }
        }

        // ===== refresh session (ถ้ามีการใช้งาน farmer ใน session/layout) =====
        Farmer fresh = imageService.findFarmerById(farmerId);
        session.setAttribute("farmer", fresh);

        if (baseChanged || touched > 0) {
            ra.addFlashAttribute("msg", "บันทึกสำเร็จ");
        } else {
            ra.addFlashAttribute("msg", "ไม่มีข้อมูลที่เปลี่ยนแปลง");
        }
        return "redirect:/farmer/profile/edit";
    }

    /* ================== private helpers ================== */

    /** หา farmerId จาก param -> session -> loggedInUser */
    private String resolveFarmerId(HttpSession session, String param) {
        if (StringUtils.hasText(param)) return param;

        if (session != null) {
            Object fid = session.getAttribute("farmerId");
            if (fid != null && String.valueOf(fid).trim().length() > 0) return String.valueOf(fid);

            Object u = session.getAttribute("loggedInUser");
            if (u != null) {
                Method m = ReflectionUtils.findMethod(u.getClass(), "getFarmerId");
                if (m != null) {
                    Object v = ReflectionUtils.invokeMethod(m, u);
                    if (v != null && String.valueOf(v).trim().length() > 0) return String.valueOf(v);
                }
                Method em = ReflectionUtils.findMethod(u.getClass(), "getEmail");
                if (em != null) {
                    Object mail = ReflectionUtils.invokeMethod(em, u);
                    if (mail != null && String.valueOf(mail).contains("@")) {
                        Farmer f = imageService.findFarmerByEmail(String.valueOf(mail));
                        if (f != null && StringUtils.hasText(f.getFarmerId())) {
                            session.setAttribute("farmerId", f.getFarmerId());
                            return f.getFarmerId();
                        }
                    }
                }
            }
        }
        return null;
    }

    /** sanitize ID: keep [a-zA-Z0-9_-], ตัดรูปแบบ "786,786" ที่ซ้ำครึ่ง */
    private String sanitizeId(String v) {
        if (v == null) return null;
        String cleaned = v.replaceAll("[^\\w-]", "");
        if (!cleaned.equals(v) && cleaned.length() % 2 == 0) {
            String firstHalf = cleaned.substring(0, cleaned.length()/2);
            String secondHalf = cleaned.substring(cleaned.length()/2);
            if (firstHalf.equals(secondHalf)) return firstHalf;
        }
        return cleaned;
    }

    private String safe(String s){ return s==null? "": s.trim(); }
    private String safeDigits(String s){ return s==null? "": s.replaceAll("\\D",""); }
}
