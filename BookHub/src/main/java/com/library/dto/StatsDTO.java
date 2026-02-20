package com.library.dto;

import lombok.Value;
import lombok.Builder;

@Value
@Builder
public class StatsDTO {
    long books;
    long users;
    long reviews;
    double avgRating;
    long reviewsLastWeek;
    String topGenre;
    String topUser;
}
