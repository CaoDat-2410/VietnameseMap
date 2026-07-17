package com.vnmap.storage.controller;

import com.vnmap.common.security.CurrentUser;
import com.vnmap.storage.dto.GenerateUploadUrlRequest;
import com.vnmap.storage.dto.UploadUrlResponse;
import com.vnmap.storage.service.StorageService;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class StorageControllerTest {
    @Test
    void forwardsAuthenticatedRequestToStorageService() {
        StorageService storage = mock(StorageService.class);
        StorageController controller = new StorageController(storage);
        CurrentUser user = new CurrentUser(4L, "student@test", "STUDENT", "ACTIVE", null, 2L);
        GenerateUploadUrlRequest request = new GenerateUploadUrlRequest("avatar.png", "image/png", "avatars", 999L);
        UploadUrlResponse response = new UploadUrlResponse("put", "public", "avatars/4/avatar.png", 123L);
        when(storage.generateUploadUrl("avatars", "avatar.png", "image/png", user)).thenReturn(response);
        assertThat(controller.generateUploadUrl(request, user).getBody().getData()).isEqualTo(response);
        verify(storage).generateUploadUrl("avatars", "avatar.png", "image/png", user);
    }
}
