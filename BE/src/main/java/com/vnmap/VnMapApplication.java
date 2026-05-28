package com.vnmap;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableCaching
public class VnMapApplication {

    public static void main(String[] args) {
        SpringApplication.run(VnMapApplication.class, args);
    }
}
