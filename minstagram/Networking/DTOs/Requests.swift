//
//  Requests.swift
//  minstagram
//

import Foundation

struct LoginRequest: Encodable {
    let emailOrUsername: String
    let password: String
}

struct RegisterRequest: Encodable {
    let email: String
    let username: String
    let password: String
}

struct EmailRequest: Encodable {
    let email: String
}

struct VerifyEmailRequest: Encodable {
    let email: String
    let code: String
}

struct UpdateProfileRequest: Encodable {
    let name: String
    let username: String
    let bio: String
    let profilePhoto: String

    init(user: UserDetail) {
        name = user.name
        username = user.username
        bio = user.bio
        profilePhoto = user.profilePhoto
    }
}

struct FollowRequest: Encodable {
    let followingId: String
}

struct RemoveFollowerRequest: Encodable {
    let followerId: String
}

/// like / unlike / save / unsave gövdesi.
struct PostIdRequest: Encodable {
    let postId: String
}

struct CreatePostRequest: Encodable {
    struct TagPayload: Encodable {
        let taggedUser: String
        let position: Position
    }

    let imageUrl: String
    let caption: String
    let tags: [TagPayload]

    init(imageUrl: String, caption: String?, tags: [Tag]) {
        self.imageUrl = imageUrl
        self.caption = caption ?? ""
        self.tags = tags.map { TagPayload(taggedUser: $0.taggedUser.id, position: $0.position) }
    }
}

struct CreateCommentRequest: Encodable {
    let postId: String
    let text: String
}
