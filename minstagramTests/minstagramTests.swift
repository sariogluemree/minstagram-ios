//
//  minstagramTests.swift
//  minstagramTests
//
//  Created by Hüseyin Emre Sarıoğlu on 19.02.2025.
//

import Foundation
import Testing
@testable import minstagram

struct minstagramTests {

    @Test func decodesPostAndCommentDatesWithAPIDecoder() throws {
        let json = """
        {
            "_id": "p1",
            "userId": {
                "_id": "u1",
                "username": "emre",
                "profilePhoto": "https://cdn.test/pp.jpg"
            },
            "imageUrl": "https://cdn.test/post.jpg",
            "caption": "Hello world",
            "createdAt": "2025-05-21T10:15:30.123Z",
            "likeCount": 3,
            "isLiked": true,
            "isSaved": false,
            "comments": [
                {
                    "_id": "c1",
                    "userId": {
                        "_id": "u2",
                        "username": "ali",
                        "profilePhoto": ""
                    },
                    "postId": "p1",
                    "text": "Nice!",
                    "createdAt": "2025-05-21T10:16:00Z"
                }
            ],
            "tags": []
        }
        """
        let post = try JSONDecoder.api.decode(Post.self, from: Data(json.utf8))
        #expect(post.id == "p1")
        #expect(post.user.username == "emre")
        #expect(post.comments.count == 1)
        #expect(post.comments[0].id == "c1")
        #expect(post.comments[0].createdAt > post.createdAt)
        #expect(!DateHelper.timeAgo(from: post.createdAt).isEmpty)
    }

    @Test func validatorChecksEmailAndCode() {
        #expect(Validator.isValidEmail("user@example.com"))
        #expect(!Validator.isValidEmail("invalid-email"))
        #expect(Validator.isValidCode("123456"))
        #expect(!Validator.isValidCode("12345"))
        #expect(!Validator.isValidCode("12345a"))
    }

}
