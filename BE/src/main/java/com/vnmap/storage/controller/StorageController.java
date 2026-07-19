package com.vnmap.storage.controller;

import com.vnmap.common.model.ApiResponse;
import com.vnmap.common.security.CurrentUser;
import com.vnmap.storage.dto.GenerateUploadUrlRequest;
import com.vnmap.storage.dto.UploadUrlResponse;
import com.vnmap.storage.service.StorageService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/storage")
public class StorageController {

    private final StorageService storageService;

    public StorageController(StorageService storageService) {
        this.storageService = storageService;
    }

    /**
     * Generates a pre-signed upload URL for Firebase Storage.
     *
     * POST /api/v1/storage/upload-url
     * Body: { "fileName": "...", "contentType": "...", "folder": "...", "userId": 123 }
     * Returns: { "uploadUrl", "publicUrl", "storagePath", "expiresAtSeconds" }
     *
     * The FE uses the uploadUrl to PUT the file directly to GCS,
     * then saves the returned publicUrl in the appropriate entity (campaign, school, event).
     */
    @PostMapping("/upload-url")
    public ResponseEntity<ApiResponse<UploadUrlResponse>> generateUploadUrl(
            @Valid @RequestBody GenerateUploadUrlRequest request,
            @AuthenticationPrincipal CurrentUser user
    ) {
        UploadUrlResponse response = storageService.generateUploadUrl(
                request.folder(),
                request.fileName(),
                request.contentType(),
                user
        );
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
