expect = require 'expect.js'
# fs = require 'fs'
_ = require 'lodash'

Resolver = require '../lib/resolver'

plugins = {
    dir: "#{__dirname}/samples"
}

describe 'Resolver', ->
    beforeEach ->
        @resolver = new Resolver plugins.dir

    describe 'Generic usage', ->
        it 'should detect missing features', ->
            result = @resolver.features 'missing'
            expect(_.keys result).to.eql ['markdown']

        it 'should detect installed features'
        it 'should detect recommended features'
        it 'should detect required features'

    describe 'Per-features usage', ->
        it 'should be able to get features required by a plugin', ->
            result = @resolver.features 'required', 'gh-blog-post-images'
            expect(_.keys result).to.eql ['info', '$']

        it 'should be able to list features provided by any number of plugins', ->
            result = @resolver.features 'required', ['gh-blog-post-images', 'gh-blog-rss']
            expect(_.keys result).to.eql ['info', '$', 'metadata', 'creation-date']
