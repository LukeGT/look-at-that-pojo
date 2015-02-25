look_at_that = require '../index'
benchmark = require 'benchmark'

describe 'performance', ->

    normal_object = null
    observable_object = null

    beforeEach ->
        normal_object = one: 1
        observable_object = look_at_that normal_object

    normal_read = -> normal_object.one
    observable_read = -> observable_object.one

    normal_write = -> normal_object.one = 1
    observable_write = -> observable_object.one = 1

    do_test = (normal_test, observable_test, done) ->

       (new benchmark.Suite)
        .add 'normal', normal_test
        .add 'observable', observable_test
        .on 'cycle', (event) -> console.log String event.target
        .on 'complete', ->
            [ normal, observable ] = @pluck 'hz'
            percentage = observable/normal * 100
            console.log "#{percentage.toFixed(2)}% of normal object's speed"
            done()
        .run async: true

    describe 'with no handlers', ->

        it 'should be comparable for reads', (done) ->
            @timeout 30000
            do_test normal_read, observable_read, done

        it 'should be comparable for writes', (done) ->
            @timeout 30000
            do_test normal_write, observable_write, done

    describe 'with 5 handlers', ->

        it 'should be comparable for reads', (done) ->

            @timeout 30000

            for a in [0...5]
                observable_object.on.change ->

            do_test normal_read, observable_read, done

        it 'should be comparable for writes', (done) ->

            @timeout 30000

            for a in [0...5]
                observable_object.on.change ->

            do_test normal_write, observable_write, done
