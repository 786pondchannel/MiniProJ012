package com.springmvc.controller;

import com.springmvc.model.Member;
import com.springmvc.service.EditMyProfileService;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/profile")
public class EditMProfileController {

    @Autowired
    private EditMyProfileService editService;

    @Value("${google.maps.apiKey:}")
    private String gmapsKey;

    /** แสดงฟอร์มแก้ไขโปรไฟล์ของผู้ใช้ที่ล็อกอิน */
    @GetMapping("/edit")
    public String showEditForm(HttpSession session, Model model) {
        Member user = (Member) session.getAttribute("loggedInUser");
        if (user == null) return "redirect:/login";

        Member fresh = editService.getCurrentProfile(user.getMemberId());
        model.addAttribute("member", fresh != null ? fresh : user);
        model.addAttribute("googleMapsApiKey", gmapsKey); // ใช้ในหน้า JSP ได้ทันที
        return "EditMProfile"; // /WEB-INF/jsp/EditMProfile.jsp
    }

    /** รับบันทึกโปรไฟล์ + อัปโหลดรูป */
    @PostMapping("/edit")
    public String updateProfile(@ModelAttribute Member form,
                                @RequestParam(value = "imageFile", required = false) MultipartFile imageFile,
                                HttpSession session,
                                RedirectAttributes ra) {
        Member user = (Member) session.getAttribute("loggedInUser");
        if (user == null) return "redirect:/login";

        // บังคับแก้ได้เฉพาะของตัวเอง
        form.setMemberId(user.getMemberId());

        try {
            // ตรวจรูปแบบ/ขนาดไฟล์อย่างง่ายฝั่งเซิร์ฟเวอร์
            if (imageFile != null && !imageFile.isEmpty()) {
                String ct = imageFile.getContentType();
                if (!StringUtils.hasText(ct) ||
                    !(ct.equals("image/jpeg") || ct.equals("image/png") || ct.equals("image/webp"))) {
                    ra.addFlashAttribute("error", "อัปโหลดได้เฉพาะไฟล์ .jpg .png .webp");
                    return "redirect:/profile/edit";
                }
                if (imageFile.getSize() > 5 * 1024 * 1024) {
                    ra.addFlashAttribute("error", "ไฟล์รูปต้องไม่เกิน 5MB");
                    return "redirect:/profile/edit";
                }
            }

            // ให้ service จัดการบันทึกข้อมูล + เก็บไฟล์
            editService.updateProfile(form, imageFile);

            // refresh session เพื่อให้ header เห็นรูปใหม่ทันที
            Member updated = editService.getCurrentProfile(user.getMemberId());
            session.setAttribute("loggedInUser", updated);

            ra.addFlashAttribute("msg", "บันทึกโปรไฟล์เรียบร้อย");
        } catch (Exception ex) {
            ra.addFlashAttribute("error", "บันทึกไม่สำเร็จ: " + ex.getMessage());
        }
        return "redirect:/profile/edit";
    }
}
