//
//  EndpointTests.swift
//  minstagramTests
//

import Foundation
import Testing
@testable import minstagram

/// Endpoint tanımlarının backend route'larıyla (path / method / auth) eşleştiğini doğrular.
struct EndpointTests {

    private struct Expectation {
        let endpoint: Endpoint
        let path: String
        let method: HTTPMethod
        let requiresAuth: Bool
        let hasBody: Bool
    }

    private static let user = UserDetail(id: "u1", username: "emre", profilePhoto: "", name: "Emre", bio: "",
                                         postsCount: 0, followersCount: 0, followingCount: 0)

    private let table: [Expectation] = [
        // Auth
        .init(endpoint: AuthEndpoint.login(LoginRequest(emailOrUsername: "e", password: "p")), path: "users/login", method: .post, requiresAuth: false, hasBody: true),
        .init(endpoint: AuthEndpoint.register(RegisterRequest(email: "e", username: "u", password: "p")), path: "users/register", method: .post, requiresAuth: false, hasBody: true),
        // Verification
        .init(endpoint: VerificationEndpoint.sendCode(email: "e"), path: "verifications/send-verification-code", method: .post, requiresAuth: false, hasBody: true),
        .init(endpoint: VerificationEndpoint.verify(email: "e", code: "123456"), path: "verifications/verify-email", method: .post, requiresAuth: false, hasBody: true),
        // User
        .init(endpoint: UserEndpoint.profile(username: "emre"), path: "users/profile/emre", method: .get, requiresAuth: false, hasBody: false),
        .init(endpoint: UserEndpoint.postProfile(username: "emre"), path: "users/profile/emre", method: .get, requiresAuth: false, hasBody: false),
        .init(endpoint: UserEndpoint.all, path: "users/all", method: .get, requiresAuth: false, hasBody: false),
        .init(endpoint: UserEndpoint.update(UpdateProfileRequest(user: EndpointTests.user)), path: "users/update", method: .put, requiresAuth: true, hasBody: true),
        .init(endpoint: UserEndpoint.delete, path: "users/delete", method: .delete, requiresAuth: true, hasBody: false),
        // Follow
        .init(endpoint: FollowEndpoint.follow(userId: "u1"), path: "follows/follow", method: .post, requiresAuth: true, hasBody: true),
        .init(endpoint: FollowEndpoint.unfollow(userId: "u1"), path: "follows/unfollow", method: .post, requiresAuth: true, hasBody: true),
        .init(endpoint: FollowEndpoint.removeFollower(userId: "u1"), path: "follows/removeFollower", method: .post, requiresAuth: true, hasBody: true),
        .init(endpoint: FollowEndpoint.followers(username: "emre"), path: "follows/followers/emre", method: .get, requiresAuth: false, hasBody: false),
        .init(endpoint: FollowEndpoint.following(username: "emre"), path: "follows/following/emre", method: .get, requiresAuth: false, hasBody: false),
        .init(endpoint: FollowEndpoint.isFollowing(userId: "u1"), path: "follows/isFollowing", method: .get, requiresAuth: true, hasBody: false),
        // Post
        .init(endpoint: PostEndpoint.create(CreatePostRequest(imageUrl: "url", caption: "c", tags: [])), path: "posts", method: .post, requiresAuth: true, hasBody: true),
        .init(endpoint: PostEndpoint.delete(id: "p1"), path: "posts/p1", method: .delete, requiresAuth: true, hasBody: false),
        .init(endpoint: PostEndpoint.detail(id: "p1"), path: "posts/post/p1", method: .get, requiresAuth: true, hasBody: false),
        .init(endpoint: PostEndpoint.forUser(userId: "u1"), path: "posts/forUser/u1", method: .get, requiresAuth: true, hasBody: false),
        .init(endpoint: PostEndpoint.feed, path: "posts/feed", method: .get, requiresAuth: true, hasBody: false),
        // Comment
        .init(endpoint: CommentEndpoint.create(postId: "p1", text: "t"), path: "comments/create", method: .post, requiresAuth: true, hasBody: true),
        // Like
        .init(endpoint: LikeEndpoint.like(postId: "p1"), path: "likes/like", method: .post, requiresAuth: true, hasBody: true),
        .init(endpoint: LikeEndpoint.unlike(postId: "p1"), path: "likes/unlike", method: .delete, requiresAuth: true, hasBody: true),
        // Saved posts
        .init(endpoint: SavedPostEndpoint.save(postId: "p1"), path: "savedPosts/save", method: .post, requiresAuth: true, hasBody: true),
        .init(endpoint: SavedPostEndpoint.unsave(postId: "p1"), path: "savedPosts/unsave", method: .delete, requiresAuth: true, hasBody: true),
        .init(endpoint: SavedPostEndpoint.getAll(userId: "u1"), path: "savedPosts/getAll/u1", method: .get, requiresAuth: true, hasBody: false),
        // Notifications
        .init(endpoint: NotificationEndpoint.list, path: "notifications", method: .get, requiresAuth: true, hasBody: false),
        .init(endpoint: NotificationEndpoint.markSeen(id: "n1"), path: "notifications/seen/n1", method: .post, requiresAuth: true, hasBody: false),
        .init(endpoint: NotificationEndpoint.hasUnseen, path: "notifications/has-unseen", method: .get, requiresAuth: true, hasBody: false),
        // Upload
        .init(endpoint: UploadEndpoint.image, path: "upload", method: .post, requiresAuth: true, hasBody: false),
    ]

    @Test func endpointsMatchBackendRoutes() {
        for item in table {
            let name = String(describing: item.endpoint)
            #expect(item.endpoint.path == item.path, "\(name) path")
            #expect(item.endpoint.method == item.method, "\(name) method")
            #expect(item.endpoint.requiresAuth == item.requiresAuth, "\(name) requiresAuth")
            #expect((item.endpoint.body != nil) == item.hasBody, "\(name) body")
        }
    }

    @Test func queryItems() {
        #expect(UserEndpoint.profile(username: "emre").queryItems == [URLQueryItem(name: "type", value: "public")])
        #expect(UserEndpoint.postProfile(username: "emre").queryItems == [URLQueryItem(name: "type", value: "post")])
        #expect(FollowEndpoint.isFollowing(userId: "u1").queryItems == [URLQueryItem(name: "followingId", value: "u1")])
        #expect(PostEndpoint.feed.queryItems == nil)
    }
}
