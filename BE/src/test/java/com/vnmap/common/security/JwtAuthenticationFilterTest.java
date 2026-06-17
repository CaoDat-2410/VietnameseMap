package com.vnmap.common.security;

import com.vnmap.auth.service.JwtService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class JwtAuthenticationFilterTest {

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void skipsAuthenticationWhenAuthorizationHeaderIsMissing() throws Exception {
        JwtService jwtService = mock(JwtService.class);
        JwtAuthenticationFilter filter = new JwtAuthenticationFilter(provider(jwtService));
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(new MockHttpServletRequest(), new MockHttpServletResponse(), chain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }

    @Test
    void setsAuthenticationForValidBearerToken() throws Exception {
        JwtService jwtService = mock(JwtService.class);
        when(jwtService.parseAccessToken("token")).thenReturn(
                new CurrentUser(1L, "staff@vnmap.local", "STAFF", "ACTIVE", 10L, null)
        );
        JwtAuthenticationFilter filter = new JwtAuthenticationFilter(provider(jwtService));
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("Authorization", "Bearer token");

        filter.doFilter(request, new MockHttpServletResponse(), new MockFilterChain());

        var auth = SecurityContextHolder.getContext().getAuthentication();
        assertThat(auth).isNotNull();
        assertThat(auth.getPrincipal()).isInstanceOf(CurrentUser.class);
        assertThat(auth.getAuthorities()).extracting("authority").containsExactly("ROLE_STAFF");
        verify(jwtService).parseAccessToken("token");
    }

    @Test
    void clearsAuthenticationForInvalidBearerToken() throws Exception {
        JwtService jwtService = mock(JwtService.class);
        when(jwtService.parseAccessToken("bad")).thenThrow(new IllegalArgumentException("Invalid token"));
        JwtAuthenticationFilter filter = new JwtAuthenticationFilter(provider(jwtService));
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("Authorization", "Bearer bad");
        SecurityContextHolder.getContext().setAuthentication(
                new org.springframework.security.authentication.UsernamePasswordAuthenticationToken(
                        "existing",
                        null
                )
        );

        filter.doFilter(request, new MockHttpServletResponse(), new MockFilterChain());

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }

    @Test
    void continuesWhenJwtServiceIsUnavailable() throws Exception {
        JwtAuthenticationFilter filter = new JwtAuthenticationFilter(provider(null));
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("Authorization", "Bearer token");

        filter.doFilter(request, new MockHttpServletResponse(), new MockFilterChain());

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }

    @Test
    void currentUserExposesSpringSecurityFlags() {
        CurrentUser active = new CurrentUser(1L, "a@b.test", "ADMIN", "ACTIVE", 1L, null);
        CurrentUser disabled = new CurrentUser(2L, "c@d.test", "STAFF", "DISABLED", 2L, null);

        assertThat(active.getUsername()).isEqualTo("a@b.test");
        assertThat(active.getPassword()).isEmpty();
        assertThat(active.isEnabled()).isTrue();
        assertThat(active.isAccountNonLocked()).isTrue();
        assertThat(active.isAccountNonExpired()).isTrue();
        assertThat(active.isCredentialsNonExpired()).isTrue();
        assertThat(active.getAuthorities()).extracting("authority").containsExactly("ROLE_ADMIN");
        assertThat(disabled.isEnabled()).isFalse();
        assertThat(disabled.isAccountNonLocked()).isFalse();
    }

    @SuppressWarnings("unchecked")
    private ObjectProvider<JwtService> provider(JwtService jwtService) {
        ObjectProvider<JwtService> provider = mock(ObjectProvider.class);
        when(provider.getIfAvailable()).thenReturn(jwtService);
        return provider;
    }
}
