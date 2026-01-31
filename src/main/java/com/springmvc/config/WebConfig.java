package com.springmvc.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.CacheControl;
import org.springframework.web.multipart.support.StandardServletMultipartResolver;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.resource.PathResourceResolver;
import org.springframework.web.servlet.view.InternalResourceViewResolver;

import java.io.File;
import java.util.concurrent.TimeUnit;

@Configuration
@EnableWebMvc
@ComponentScan(basePackages = "com.springmvc")
public class WebConfig implements WebMvcConfigurer {

    @Bean
    public InternalResourceViewResolver viewResolver(){
        InternalResourceViewResolver vr = new InternalResourceViewResolver();
        vr.setPrefix("/WEB-INF/jsp/");
        vr.setSuffix(".jsp");
        vr.setContentType("text/html; charset=UTF-8");
        vr.setOrder(0);
        return vr;
    }

    // ใช้ตัวมาตรฐานของ Spring 6 (Servlet 3+)
    @Bean
    public StandardServletMultipartResolver multipartResolver() {
        return new StandardServletMultipartResolver();
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 1) ไฟล์ใน WAR (assets ภายในโปรเจ็กต์)
        registry.addResourceHandler("/assets/**")
                .addResourceLocations("/assets/")
                .setCacheControl(CacheControl.noCache().mustRevalidate())
                .resourceChain(true)
                .addResolver(new PathResourceResolver());

        // 2) ไฟล์อัปโหลดนอก WAR — ผูกกับตัวแปรแวดล้อม UPLOAD_DIR (ถ้ามี)
        //    ถ้าไม่กำหนด จะ fallback ไปที่ <project>/uploads/ (ใช้ได้ตอนรันในเครื่อง)
        String uploadDir = resolveUploadDir();

        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:" + uploadDir)
                // ไม่ cache เพื่อเห็นไฟล์ใหม่ทันที
                .setCacheControl(CacheControl.noStore())
                .resourceChain(true)
                .addResolver(new PathResourceResolver());

        // 3) classpath static (เผื่ออนาคต)
        registry.addResourceHandler("/static/**")
                .addResourceLocations("classpath:/static/", "classpath:/public/")
                .setCacheControl(CacheControl.maxAge(1, TimeUnit.HOURS).cachePublic())
                .resourceChain(true)
                .addResolver(new PathResourceResolver());
    }

    /**
     * หา path ที่แท้จริงของโฟลเดอร์ uploads/
     * ลำดับความสำคัญ:
     * 1) ENV: UPLOAD_DIR (ถ้ามี)
     * 2) ถ้า Windows: <project>/uploads/ (จาก user.dir)
     * 3) ถ้า Linux/Docker: /app/uploads/ (ถ้ามีจริง) ไม่งั้น <project>/uploads/
     */
    private String resolveUploadDir() {
        String env = System.getenv("UPLOAD_DIR");
        if (env != null && !env.trim().isEmpty()) {
            return normalizeDir(env.trim());
        }

        String userDir = System.getProperty("user.dir");
        String projectUploads = normalizeDir(userDir + File.separator + "uploads");

        String os = System.getProperty("os.name", "").toLowerCase();
        if (os.contains("win")) {
            // รันบน Windows ให้ใช้ uploads ในโปรเจคเป็นค่าเริ่มต้น
            return projectUploads;
        }

        // รันบน Linux/Docker: ถ้ามี /app/uploads/ ใช้อันนี้ ไม่งั้น fallback เป็น uploads ในโปรเจค
        String dockerUploads = normalizeDir("/app/uploads");
        if (new File(stripTrailingSlash(dockerUploads)).exists()) {
            return dockerUploads;
        }
        return projectUploads;
    }

    /**
     * ทำให้ path เป็นรูปแบบ directory ที่ลงท้ายด้วย / และรองรับ Windows backslash
     * และรองรับกรณีที่ส่งมาด้วย file: อยู่แล้ว (จะถอดออกก่อน)
     */
    private String normalizeDir(String path) {
        String p = path;

        // ถ้าใส่ file: มาแล้ว ให้ถอดออกก่อน (กันซ้ำ file:file:)
        if (p.startsWith("file:")) {
            p = p.substring("file:".length());
        }

        // แปลง \ เป็น /
        p = p.replace("\\", "/");

        // ถ้าเป็น Windows drive เช่น D:/... ให้แน่ใจว่า file: ใช้รูปแบบ file:/D:/...
        // (เราใส่ "file:" ตอน addResourceLocations แล้ว)
        if (!p.endsWith("/")) {
            p = p + "/";
        }
        return p;
    }

    private String stripTrailingSlash(String p) {
        if (p == null) return null;
        if (p.endsWith("/")) return p.substring(0, p.length() - 1);
        return p;
    }

    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        registry.addViewController("/").setViewName("main");
        registry.addViewController("/main").setViewName("main");
    }
}
