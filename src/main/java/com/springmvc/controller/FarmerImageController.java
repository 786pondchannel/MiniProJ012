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
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.lang.reflect.Method;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * จัดการหน้าแก้ไขโปรไฟล์ฟาร์ม + อัปโหลด/ลบ/เรียงรูปภาพ
 * โน้ต: คลาสนี้ไม่มีการ redirect ไปที่ /preorder/product/edit/... ใดๆ ทั้งสิ้น
 */
@Controller
@RequestMapping("/farmer/profile")
public class FarmerImageController {

    private static final int MAX_GALLERY = 10;

    @Autowired private FarmerImageService imageService;
    @Autowired private ServletContext servletContext;

    /** สลับบริบทเป็นฟาร์มที่ระบุแล้วไปหน้าแก้ไข */
    @GetMapping("/as/{farmerId}")
    public String impersonate(@PathVariable String farmerId, HttpSession session) {
        if (StringUtils.hasText(farmerId)) {
            session.setAttribute("farmerId", farmerId.trim());
        }
        return "redirect:/farmer/profile/edit";
    }

    /** GET: หน้าแก้ไขโปรไฟล์ฟาร์ม */
    @GetMapping("/edit")
    public String edit(@RequestParam(value = "farmerId", required = false) String farmerIdParam,
                       @RequestParam(value = "updated", required = false) String updated,
                       @RequestParam(value = "back", required = false) String back,
                       HttpSession session,
                       Model model) {

        String farmerId = resolveFarmerId(session, farmerIdParam);
        if (!StringUtils.hasText(farmerId)) {
            model.addAttribute("error", "✖ ไม่พบรหัสฟาร์ม (ไปที่ /farmer/profile/as/{farmerId} หรือแนบ ?farmerId=)");
            return "EditFarmerProfile";
        }

        Farmer farmer = imageService.findFarmerById(farmerId);
        if (farmer == null) {
            model.addAttribute("error","✖ ไม่พบฟาร์ม: " + farmerId);
            return "EditFarmerProfile";
        }

        List<FarmerImage> gallery = imageService.findGallery(farmerId);

        model.addAttribute("farmer", farmer);
        model.addAttribute("farmerImages", gallery != null ? gallery : Collections.emptyList());

        // ใช้กับ JSP เพื่อโชว์โมดัลสำเร็จ/คงปุ่ม back
        if (StringUtils.hasText(updated)) model.addAttribute("justUpdated", true);
        if (StringUtils.hasText(back))    model.addAttribute("back", back);

        return "EditFarmerProfile";
    }

    /** POST: บันทึกการแก้ไขโปรไฟล์ + จัดการรูปภาพ */
    @PostMapping("/edit")
    public String save(Farmer farmer,
                       HttpSession session,
                       @RequestParam(value = "farmImage", required = false) MultipartFile farmImage,
                       @RequestParam(value = "slipImage", required = false) MultipartFile slipImage,
                       @RequestParam(value = "galleryFiles", required = false) MultipartFile[] galleryFiles,
                       @RequestParam(value = "deleteImageIds", required = false) List<Long> deleteIds,
                       @RequestParam(value = "sortImageIds", required = false) String sortCsv,
                       @RequestParam(value = "confirmPassword", required = false) String confirmPassword,
                       @RequestParam(value = "back", required = false) String back,
                       RedirectAttributes ra) {

        String rawId = resolveFarmerId(session, null);
        if (!StringUtils.hasText(rawId)) {
            ra.addFlashAttribute("error","✖ ไม่พบรหัสฟาร์ม");
            return "redirect:/farmer/profile/edit";
        }
        String farmerId = sanitizeId(rawId);

        Farmer current = imageService.findFarmerById(farmerId);
        if (current == null) {
            ra.addFlashAttribute("error","✖ ไม่พบฟาร์ม: " + farmerId);
            return "redirect:/farmer/profile/edit";
        }

        // ===== validate ฟิลด์ข้อความ =====
        Map<String,String> fe = new LinkedHashMap<>();
        String farmName = safe(farmer.getFarmName());
        String email    = safe(farmer.getEmail());
        String phone    = safeDigits(farmer.getPhoneNumber());
        String address  = safe(farmer.getAddress());
        String farmLoc  = safe(farmer.getFarmLocation());
        String pwd      = safe(farmer.getPassword());

        if (!StringUtils.hasText(farmName)) fe.put("farmName","กรอกชื่อฟาร์ม");
        if (StringUtils.hasText(email) && !email.contains("@")) fe.put("email","อีเมลไม่ถูกต้อง");
        if (StringUtils.hasText(phone) && !phone.matches("^0\\d{9}$")) fe.put("phoneNumber","เบอร์ต้อง 10 หลักขึ้นต้น 0");
        if (!StringUtils.hasText(address)) fe.put("address","กรุณากรอกที่อยู่");
        if (!StringUtils.hasText(farmLoc)) fe.put("farmLocation","กรุณากรอกที่ตั้งฟาร์ม");
        if (StringUtils.hasText(pwd)) {
            if (pwd.length() < 8) fe.put("password","อย่างน้อย 8 ตัวอักษร");
            if (confirmPassword == null || !pwd.equals(confirmPassword)) fe.put("confirmPassword","ยืนยันรหัสผ่านไม่ตรงกัน");
        }
        if (!fe.isEmpty()) {
            ra.addFlashAttribute("error","กรุณาแก้ไขข้อมูลที่ไฮไลต์สีแดง");
            ra.addFlashAttribute("fieldErrors", fe);
            return buildRedirectToEdit(false, back); // กลับ edit พร้อมคง back ถ้ามี
        }

        // ===== merge base fields =====
        current.setFarmName(farmName);
        current.setEmail(email);
        current.setPhoneNumber(phone);
        current.setAddress(address);
        current.setFarmLocation(farmLoc);
        if (StringUtils.hasText(pwd)) current.setPassword(pwd);

        int touched = 0;

        // ===== upload ภาพหลัก/สลิป =====
        try {
            if (farmImage != null && !farmImage.isEmpty()) {
                String web = imageService.saveProfileImage(farmerId, farmImage, servletContext);
                if (StringUtils.hasText(web)) { current.setImageF(web); touched++; }
            }
            if (slipImage != null && !slipImage.isEmpty()) {
                String web = imageService.saveSlipImage(farmerId, slipImage, servletContext);
                if (StringUtils.hasText(web)) {
                    try {
                        Method m = ReflectionUtils.findMethod(Farmer.class, "setSlipUrl", String.class);
                        if (m != null) ReflectionUtils.invokeMethod(m, current, web);
                    } catch (Exception ignore) {}
                    touched++;
                }
            }
        } catch (RuntimeException ex) {
            ra.addFlashAttribute("error", ex.getMessage());
            return buildRedirectToEdit(false, back);
        }

        boolean baseChanged = imageService.updateFarmerBasicReturn(current);

        // ===== ลบภาพแกลเลอรี =====
        if (deleteIds != null && !deleteIds.isEmpty()) {
            touched += imageService.deleteGalleryByIdsCount(farmerId, deleteIds, true, servletContext);
        }

        // ===== เรียงรูปใหม่ =====
        if (StringUtils.hasText(sortCsv)) {
            List<Long> ordered = Stream.of(sortCsv.split(","))
                    .map(String::trim)
                    .filter(s -> s.matches("\\d+"))
                    .map(Long::valueOf)
                    .collect(Collectors.toList());
            if (!ordered.isEmpty()) touched += imageService.reorderKeptImagesCount(farmerId, ordered);
        }

        // ===== เพิ่มภาพใหม่ (จำกัดรวมสูงสุด 10) =====
        if (galleryFiles != null && galleryFiles.length > 0) {
            List<MultipartFile> list = Arrays.stream(galleryFiles)
                    .filter(Objects::nonNull).filter(fx -> !fx.isEmpty())
                    .collect(Collectors.toList());

            if (!list.isEmpty()) {
                int curCount = imageService.countGallery(farmerId);
                int canAdd = Math.max(0, MAX_GALLERY - curCount);
                if (canAdd <= 0) {
                    ra.addFlashAttribute("error","มีรูปครบ " + MAX_GALLERY + " แล้ว ลบรูปเดิมก่อน");
                    return buildRedirectToEdit(false, back);
                }
                if (list.size() > canAdd) list = list.subList(0, canAdd);
                touched += imageService.saveNewGalleryImagesCount(farmerId, list, servletContext);
            }
        }

        // ===== refresh session farmer & อัปเดตรูป avatar ของ loggedInUser =====
        Farmer fresh = imageService.findFarmerById(farmerId);
        session.setAttribute("farmer", fresh);

        Object u = session.getAttribute("loggedInUser");
        if (u != null && fresh != null && StringUtils.hasText(fresh.getImageF())) {
            try {
                Method setImg = ReflectionUtils.findMethod(u.getClass(), "setImageUrl", String.class);
                if (setImg != null) {
                    ReflectionUtils.invokeMethod(setImg, u, fresh.getImageF());
                    session.setAttribute("loggedInUser", u);
                }
            } catch (Exception ignore) {}
        }

        if (baseChanged || touched > 0) {
            ra.addFlashAttribute("msg","✔ บันทึกสำเร็จ");
        } else {
            ra.addFlashAttribute("msg","ไม่มีข้อมูลที่เปลี่ยนแปลง");
        }

        // กลับหน้าแก้ไข พร้อมธง updated=1 และคง back เดิมหากมี
        return buildRedirectToEdit(true, back);
    }

    /* ==================== helpers ==================== */

    /** รวม logic redirect ไปหน้าแก้ไข + แนบ updated/back ให้เรียบร้อย */
    private String buildRedirectToEdit(boolean updated, String back) {
        StringBuilder sb = new StringBuilder("redirect:/farmer/profile/edit");
        List<String> params = new ArrayList<>();
        if (updated) params.add("updated=1");
        if (StringUtils.hasText(back)) {
            params.add("back=" + URLEncoder.encode(back, StandardCharsets.UTF_8));
        }
        if (!params.isEmpty()) {
            sb.append("?").append(String.join("&", params));
        }
        return sb.toString();
    }

    /** หาค่า farmerId จาก param -> session -> loggedInUser */
    private String resolveFarmerId(HttpSession session, String param) {
        if (StringUtils.hasText(param)) return param;
        if (session != null) {
            Object fid = session.getAttribute("farmerId");
            if (fid != null && String.valueOf(fid).trim().length() > 0) return String.valueOf(fid);

            Object u = session.getAttribute("loggedInUser");
            if (u != null) {
                try {
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
                } catch (Exception ignore) {}
            }
        }
        return null;
    }

    private String sanitizeId(String v) {
        if (v == null) return null;
        String cleaned = v.replaceAll("[^\\w-]", "");
        if (!cleaned.equals(v) && cleaned.length() % 2 == 0) {
            String first = cleaned.substring(0, cleaned.length()/2);
            String second = cleaned.substring(cleaned.length()/2);
            if (first.equals(second)) return first;
        }
        return cleaned;
    }

    private String safe(String s){ return s==null? "": s.trim(); }
    private String safeDigits(String s){ return s==null? "": s.replaceAll("\\D",""); }
}
