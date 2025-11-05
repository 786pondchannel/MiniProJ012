package com.springmvc.controller;

import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@Controller
@RequestMapping("/buyer") // <<-- ย้ายฐาน path ออกไปจาก /orders เพื่อเลี่ยงชน
public class OrdersReceiptController {

    @PostMapping("/orders/{orderId}/upload-receipt")
    public String uploadReceipt(
            @PathVariable String orderId,
            @RequestParam(value = "reference", required = false) String reference,
            @RequestParam("file") MultipartFile file,
            HttpSession session
    ) {
        // ถ้าคุณอยากให้ตัวนี้เป็นเพียง "ทางเลือก" ก็รีไดเร็กต์ไปยัง endpoint มาตรฐาน
        // ที่อยู่ใน BuyerOrdersController ก็ได้ (จะไม่ชน เพราะ path ต่างกัน)
        return "redirect:/orders/" + orderId + "/upload-receipt";
    }
}
