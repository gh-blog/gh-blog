expect = require 'expect.js'

{ ManifestError } = require './errors'

module.exports.validate = (manifest, filename = null) ->

    # Must be valid JSON
    try
        expect(JSON.stringify).withArgs(manifest).to.not.throwException()
        expect(JSON.parse JSON.stringify manifest).to.eql manifest
    catch err
        throw new ManifestError 'MALFORMED_JSON', filename, err

    try
        expect(manifest.name).to.be.ok()
        expect(root = manifest['gh-blog']).to.be.an 'object'
    catch err
        throw new ManifestError 'MALFORMED_MANIFEST_ROOT', filename, err

    try
        expect(root).to.have.property 'provides'
    catch err
        throw new ManifestError 'MISSING_MANIFEST_ENTRY', filename, err

    try
        expect(root.provides).to.be.an 'array'
        expect(root.provides).to.not.be.empty()
        expect(element).to.be.a 'string' for element in root.provides
    catch err
        throw new ManifestError 'MALFORMED_MANIFEST_ENTRY', filename, err

    if root.requires
        try
            expect(root.requires).to.be.an 'array'
            expect(root.requires).to.not.be.empty()
            expect(element).to.be.a 'string' for element in root.requires
        catch err
            throw new ManifestError 'MALFORMED_MANIFEST_ENTRY', filename, err

        # Plugins should not require features they already provide
        try
            for feature in root.provides
                expect(root.requires).to.not.contain feature
        catch err
            throw new ManifestError 'CIRCULAR_DEPENDENCY', filename, err

    if root.recommends
        try
            expect(root.recommends).to.be.an 'array'
            expect(root.recommends).to.not.be.empty()
            expect(element).to.be.a 'string' for element in root.recommends
        catch err
            throw new ManifestError 'MALFORMED_MANIFEST_ENTRY', filename, err

        # Plugins should not recommend features they already provide,
        try
            for feature in root.provides
                expect(root.recommends).to.not.contain feature
        catch err
            throw new ManifestError 'CIRCULAR_DEPENDENCY', filename, err

        # nor should they require features they recommend...
        if root.requires
            try
                for feature in root.requires
                    expect(root.recommends).to.not.contain feature
            catch err
                throw new ManifestError 'DEPENDENCY_CONFLICT', filename, err

    yes