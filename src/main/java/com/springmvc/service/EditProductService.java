package com.springmvc.service;

import com.springmvc.model.Product;
import com.springmvc.model.ProductImage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.util.*;

@Service
public class EditProductService {

    @Autowired private ProductService productService;
    @Autowired private CategoryService categoryService;
    @Autowired private CreateProductService createProductService;

    public Product getEditable(String productId, String currentMemberId) {
        Product p = productService.getProduct(productId);
        if (p == null) throw new IllegalArgumentException("ไม่พบสินค้า");
        if (currentMemberId == null || !Objects.equals(currentMemberId, p.getFarmerId())) {
            throw new SecurityException("คุณไม่มีสิทธิ์แก้ไขสินค้านี้");
        }
        return p;
    }

    public List<?> getAllCategories() { return categoryService.getAllCategories(); }

    public List<ProductImage> getImages(String productId) { return createProductService.getImages(productId); }

    public void update(Product product,
                       MultipartFile[] newImages,
                       String currentMemberId,
                       String[] deleteImageIds) {

        if (product == null || product.getProductId() == null || product.getProductId().isBlank()) {
            throw new IllegalArgumentException("ข้อมูลสินค้าไม่ครบ");
        }
        Product before = productService.getProduct(product.getProductId());
        if (before == null) throw new IllegalArgumentException("ไม่พบสินค้า");
        if (currentMemberId == null || !Objects.equals(currentMemberId, before.getFarmerId())) {
            throw new SecurityException("คุณไม่มีสิทธิ์แก้ไขสินค้านี้");
        }

        if (product.getProductname() != null) product.setProductname(product.getProductname().trim());
        if (product.getDescription() != null) product.setDescription(product.getDescription().trim());
        if (product.getStock() < 0) product.setStock(0);

        List<org.springframework.web.multipart.MultipartFile> files =
                (newImages != null) ? Arrays.asList(newImages) : Collections.emptyList();

        createProductService.update(product, files, currentMemberId, deleteImageIds);
    }
}
