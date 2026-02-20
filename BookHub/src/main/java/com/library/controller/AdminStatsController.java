package com.library.controller;

import com.library.service.StatsService;
import com.library.dto.StatsDTO;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import io.swagger.v3.oas.annotations.Operation;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
public class AdminStatsController {
    private final StatsService statsService;

    public AdminStatsController(StatsService statsService) {
        this.statsService = statsService;
    }

    @GetMapping("/stats")
    @Operation(summary = "Basic stats", description = "Returns basic platform stats")
    public StatsDTO stats() {
        return statsService.getStats();
    }

    @GetMapping("/stats/extended")
    @Operation(summary = "Extended stats", description = "Returns extended analytics for admin dashboard")
    public Map<String, Object> extended() {
        return statsService.getExtendedStats();
    }
}
