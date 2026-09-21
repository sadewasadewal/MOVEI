//
//  AdminMovieListView.swift
//  MOVEI
//

import SwiftUI

public struct AdminMovieListView: View {
    @ObservedObject private var movieService = MovieService.shared
    @State private var editingMovie: Movie?
    @State private var isCreating = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                ForEach(movieService.movies) { movie in
                    HStack(spacing: 14) {
                        RobustAsyncImage(candidateURLs: [movie.resolvedPosterURL, movie.resolvedBackdropURL].compactMap { $0 }) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle().fill(AppTheme.passBackground)
                        }
                        .frame(width: 46, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(movie.title)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.ink)
                                Spacer()
                                StatusBadge(status: movie.status)
                            }
                            Text("\(movie.genre) · \(movie.runtime)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingMovie = movie
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Archive", role: .destructive) {
                            movieService.archive(movieID: movie.id)
                        }
                        if movie.status == .draft {
                            Button("Publish") {
                                _ = movieService.publish(movieID: movie.id)
                            }
                            .tint(AppTheme.success)
                        }
                    }
                }
            }
            .navigationTitle("Movie Catalog")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCreating = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.ink)
                    }
                }
            }
            .sheet(isPresented: $isCreating) {
                AdminMovieEditorView(movie: Movie(
                    id: UUID().uuidString,
                    title: "",
                    slug: "",
                    tagline: "",
                    genres: ["Action"],
                    runtimeMinutes: 120,
                    posterURL: "",
                    backdropURL: "",
                    status: .draft
                ))
            }
            .sheet(item: $editingMovie) { movie in
                AdminMovieEditorView(movie: movie)
            }
        }
    }
}

public struct StatusBadge: View {
    let status: MovieStatus

    public var body: some View {
        Text(status.title.uppercased())
            .font(.system(size: 9, weight: .black))
            .tracking(1.2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .published: return AppTheme.success
        case .draft: return AppTheme.warning
        case .archived: return AppTheme.danger
        }
    }
}

public struct AdminMovieEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var movieService = MovieService.shared
    @State private var movie: Movie
    @State private var genresString: String
    @State private var runtimeString: String
    @State private var showPreview = false
    @State private var validationErrors: [String] = []

    public init(movie: Movie) {
        _movie = State(initialValue: movie)
        _genresString = State(initialValue: movie.genres.joined(separator: ", "))
        _runtimeString = State(initialValue: "\(movie.runtimeMinutes)")
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Movie Title", text: $movie.title)
                    TextField("URL Slug", text: $movie.slug)
                    TextField("Tagline", text: $movie.tagline)
                    TextField("Genres (comma separated)", text: $genresString)
                    TextField("Runtime (minutes)", text: $runtimeString)
                        .keyboardType(.numberPad)
                    TextField("Description", text: $movie.description, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section("Artwork & Media Requirements") {
                    ImageUploaderView(requirement: MOVEIConfig.ImageSpecs.poster, imageURL: $movie.posterURL)
                    ImageUploaderView(requirement: MOVEIConfig.ImageSpecs.backdrop, imageURL: $movie.backdropURL)
                    TextField("Trailer URL", text: Binding(get: { movie.trailerURL ?? "" }, set: { movie.trailerURL = $0 }))
                }

                Section("Publishing") {
                    Picker("Status", selection: $movie.status) {
                        ForEach(MovieStatus.allCases) { s in
                            Text(s.title).tag(s)
                        }
                    }

                    if !validationErrors.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(validationErrors, id: \.self) { err in
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(AppTheme.danger)
                                    Text(err)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.danger)
                                }
                            }
                        }
                    }

                    Button {
                        showPreview = true
                    } label: {
                        HStack {
                            Image(systemName: "eye.fill")
                            Text("Preview Movie Detail View")
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle(movie.title.isEmpty ? "New Movie" : "Edit Movie")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveMovie()
                    }
                    .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showPreview) {
                MovieDetailView(movie: movie) {
                    // Preview action
                }
            }
        }
    }

    private func saveMovie() {
        movie.genres = genresString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if let mins = Int(runtimeString) {
            movie.runtimeMinutes = mins
            let h = mins / 60
            let m = mins % 60
            movie.runtime = "\(h)h \(m)m"
        }
        if movie.slug.isEmpty {
            movie.slug = movie.title.lowercased().replacingOccurrences(of: " ", with: "-")
        }

        if movie.status == .published {
            let (valid, reasons) = movieService.canPublish(movie: movie)
            if !valid {
                validationErrors = reasons
                return
            }
        }

        movieService.addOrUpdate(movie: movie)
        dismiss()
    }
}
