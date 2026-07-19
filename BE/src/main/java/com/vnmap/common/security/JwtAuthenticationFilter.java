package com.vnmap.common.security;

import com.vnmap.auth.service.JwtService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final ObjectProvider<JwtService> jwtService;

    public JwtAuthenticationFilter(ObjectProvider<JwtService> jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            JwtService service = jwtService.getIfAvailable();
            if (service == null) {
                filterChain.doFilter(request, response);
                return;
            }
            try {
                CurrentUser user = service.parseAccessToken(header.substring(7));
                UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                        user,
                        null,
                        user.getAuthorities()
                );
                SecurityContextHolder.getContext().setAuthentication(auth);
            } catch (IllegalArgumentException ignored) {
                SecurityContextHolder.clearContext();
            }
        }
        filterChain.doFilter(request, response);
    }
}
