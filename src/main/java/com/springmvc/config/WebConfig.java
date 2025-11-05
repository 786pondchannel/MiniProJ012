package com.springmvc.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.view.InternalResourceViewResolver;

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

    @Bean
    public org.springframework.web.multipart.MultipartResolver multipartResolver() {
        return new org.springframework.web.multipart.support.StandardServletMultipartResolver();
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/assets/**")
                .addResourceLocations("/assets/")
                .setCachePeriod(0);

        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:///D:/Toos/png/")
                .setCachePeriod(0);

        registry.addResourceHandler("/static/**")
                .addResourceLocations("classpath:/static/", "classpath:/public/")
                .setCachePeriod(0);
    }

    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        registry.addViewController("/").setViewName("main");
        registry.addViewController("/main").setViewName("main");
        // ❌ ห้าม map /product/list/Farmer ที่นี่
        // ให้ใช้ Controller จริงเพื่อใส่ products/categories ลง model
    }
}
