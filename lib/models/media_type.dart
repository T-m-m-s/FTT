enum MediaType {
  game,
  movie,
  tvShow;

  String get displayName {
    switch (this) {
      case MediaType.game:
        return 'Game';
      case MediaType.movie:
        return 'Movie';
      case MediaType.tvShow:
        return 'TV Series';
    }
  }

  String get pluralName {
    switch (this) {
      case MediaType.game:
        return 'Games';
      case MediaType.movie:
        return 'Movies';
      case MediaType.tvShow:
        return 'TV Shows';
    }
  }

  String get actionVerb {
    switch (this) {
      case MediaType.game:
        return 'Playing';
      case MediaType.movie:
      case MediaType.tvShow:
        return 'Watching';
    }
  }

  String get pastActionVerb {
    switch (this) {
      case MediaType.game:
        return 'Played';
      case MediaType.movie:
      case MediaType.tvShow:
        return 'Watched';
    }
  }
}
