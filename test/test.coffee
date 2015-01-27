look_at_that = require '../index'
chai = require 'chai'
chai.should()
expect = chai.expect

describe 'Looking at that POJO', ->

    pojo = null
    object = {
        one: 1
        two: 2
        three:
            four: 4
            five: 5
            six:
                seven: 7
    }

    beforeEach ->
        pojo = look_at_that object

    it 'still works with JSON.stringify()', ->
        JSON.stringify(pojo).should.equal JSON.stringify(object)

    it 'still lets me iterate over its properties', ->
        keys = (key for key of pojo)
        keys.should.have.length 3
        keys.should.contain 'one'
        keys.should.contain 'two'
        keys.should.contain 'three'

    describe 'listening to object change events', ->

        describe 'at the root object', ->

            it 'should have itself as the first parameter', (done) ->

                pojo.on.change (arg) ->
                    arg.should.equal pojo
                    done()

                pojo.one = 'one'

            it 'should have itself as the context', (done) ->

                pojo.on.change ->
                    this.should.equal pojo
                    done()

                pojo.two = 'two'

            it 'should work for nested object changes', (done) ->
                pojo.on.change -> done()
                pojo.three.six = {}

            it 'should work for nested key changes', (done) ->
                pojo.on.change -> done()
                pojo.three.six.seven = "seven"

        it 'should work for a nested object', (done) ->
            pojo.three.on.change -> done()
            pojo.three.six = {}

    describe 'listening to key change events', ->

        it 'should have the new value as the first argument', (done) ->

            new_value = 'new_value'

            pojo.on.change 'one', (arg) ->
                arg.should.equal new_value
                done()

            pojo.one = new_value

        it 'should have the parent object as the second argument', (done) ->

            pojo.on.change 'one', (_, arg) ->
                arg.should.equal pojo
                done()

            pojo.one = 'one'


        it 'should have the parent object as the context', (done) ->

            pojo.on.change 'two', ->
                this.should.equal pojo
                done()

            pojo.two = 'two'

        it 'should work even if the value of the key is an observable object', (done) ->

            pojo.on.change 'three', -> done()
            pojo.three = {}

    describe 'listening to both kinds of events simultaneously', ->

        it 'should happen in the correct order', (done) ->

            key_change = false
            object_change = false

            pojo.on.change ->
                key_change.should.be.true
                object_change.should.be.false
                object_change = true
                done()

            pojo.on.change 'one', ->
                key_change.should.be.false
                object_change.should.be.false
                key_change = true

            pojo.one = 'one'

        it 'shouldn\'t misfire a key change for an object change', (done) ->

            key_change = false

            pojo.three.on.change ->
                key_change.should.be.false
                done()

            pojo.three.on.change 'four', -> key_change = true

            pojo.three.six = {}

    describe 'listening to multiple events', ->

        it 'should fire them in the correct order', (done) ->

            order = [1..10]
            actual_order = []

            check = ->
                order.should.deep.equal actual_order
                done()

            for n in order
                do (n) -> pojo.on.change ->
                    actual_order.push n
                    check() if actual_order.length == order.length

            pojo.one = 'one'

    describe 'removing an object change event', ->

        it 'should not trigger', ->

            delete_me = pojo.on.change ->
                throw new Error("I should not have run")

            delete_me()
            pojo.one = 'one'

        it 'should still trigger other events attached to the same change', ->

            count = 0

            pojo.on.change -> count++
            delete_me = pojo.on.change -> count++
            pojo.on.change -> count++

            delete_me()

            pojo.one = 'one'

            count.should.equal 2

    describe 'removing a key change event', ->

        it 'should not trigger', ->

            delete_me = pojo.on.change 'one', ->
                throw new Error("I should not have run")

            delete_me()
            pojo.one = 'one'

        it 'should still trigger other events attached to the same change', ->

            count = 0

            pojo.on.change 'one', -> count++
            delete_me = pojo.on.change 'one', -> count++
            pojo.on.change 'one', -> count++

            delete_me()

            pojo.one = 'one'

            count.should.equal 2

    describe 'listening to a key before it exists', ->

        it 'should work', (done) ->

            pojo.on.change 'eight', ->
                done()

            pojo.eight = 'eight'

    describe 'setting a new key', ->

        it 'should bubble changes up to existing object listeners', (done) ->

            pojo.on.change -> done()
            pojo.set 'eight', 'eight'

        it 'should return the set value, just like real assignment', ->
            (pojo.set 'eight', 'eight').should.equal('eight')

    describe 'assigning an object over an object', ->

        it 'should result in an observable object', ->

            root_count = 0

            pojo.on.change -> root_count++

            pojo.three = {
                eight: 8
                nine: 9
                ten:
                    eleven: 11
                    twelve: 12
            }

            pojo.three.eight = 'eight'

            root_count.should.equal 2

        it 'should allow nested objects to have event handlers', (done) ->

            pojo.three = {
                eight: 8
                nine: 9
                ten:
                    eleven: 11
                    twelve: 12
            }

            pojo.three.ten.on.change -> done()
            pojo.three.ten.eleven = 'eleven'

        it 'should work even if you use set()', (done) ->

            pojo.set 'three', {
                eight: 8
                nine: 9
                ten:
                    eleven: 11
                    twelve: 12
            }

            pojo.three.ten.on.change -> done()
            pojo.three.ten.eleven = 'eleven'

    describe 'setting a value silently', ->

        it 'should not trigger an object change', ->

            pojo.on.change -> throw new Error('This should not have run')
            pojo.set.silently 'one', 'one'

        it 'should not trigger a key change', ->

            pojo.on.change 'one', -> throw new Error('This should not have run')
            pojo.set.silently 'one', 'one'

    describe 'Arrays', ->

        describe 'basic operations', ->

            changed = null
            array = null

            beforeEach ->
                changed = false
                array = [ 1, 2, key: 'value', 3 ]
                pojo = look_at_that array: array
                pojo.array.on.change -> changed = true

            afterEach ->
                changed.should.be.true

            it 'can be popped', -> pojo.array.pop().should.equal array.pop()
            it 'can be pushed', -> pojo.array.push().should.equal array.push()
            it 'can be reversed', -> pojo.array.reverse().should.deep.equal array.reverse()
            it 'can be shifted', -> pojo.array.shift().should.equal array.shift()
            it 'can be unshifted', -> pojo.array.unshift().should.equal array.unshift()
            it 'can be spliced', -> pojo.array.splice().should.deep.equal array.splice()
            it 'can be sorted', -> pojo.array.sort().should.deep.equal array.sort()

        it 'instruments objects within it', (done) ->

            array = look_at_that [ key: 'value' ]
            array[0].on.change -> done()
            array[0].key = true

        it 'responds to changes in objects within it', (done) ->

            array = look_at_that [ key: 'value' ]
            array.on.change -> done()
            array[0].key = true

        it 'responds to changes made with set', (done) ->

            array = [ 1, 2, 3, 4 ]

            observable = look_at_that array
            observable.on.change -> done()
            observable.set 0, 0

            array[0] = 0
            observable.should.deep.equal array

    describe 'Not just plain old javascript objects', ->

        class Test

        observable = look_at_that
            value: new Test()

        it 'is still of its original type', ->
            (observable.value instanceof Test).should.be.true

        it 'is not observable', ->

            fired = false

            observable.on.change ->
                fired = true

            observable.value.property = true
            fired.should.be.false

        it 'does not have a set method', ->
            expect(observable.value.set).to.be.undefined

    describe 'performance', ->

        @timeout 5000

        normal_object = null
        observable_object = null

        beforeEach ->
            normal_object = one: 1
            observable_object = look_at_that normal_object

        repeat = (count, func, callback) ->
            start = Date.now()
            func() for a in [0...count]
            return count/(Date.now() - start)

        normal_read = -> normal_object.one
        observable_read = -> observable_object.one

        normal_write = -> normal_object.one = 1
        observable_write = -> observable_object.one = 1

        describe 'with no handlers', ->

            it 'should be comparable for reads', ->

                normal_count = repeat 10000000, normal_read
                observable_count = repeat 10000000, observable_read
                percentage = observable_count/normal_count * 100
                console.log "#{percentage.toFixed(2)}% of normal object's speed"

            it 'should be comparable for writes', ->

                normal_count = repeat 10000000, normal_write
                observable_count = repeat 10000000, observable_write
                percentage = observable_count/normal_count * 100
                console.log "#{percentage.toFixed(2)}% of normal object's speed"

        describe 'with 5 handlers', ->

            it 'should be comparable for reads', ->

                for a in [0...5]
                    observable_object.on.change ->

                normal_count = repeat 10000000, normal_read
                observable_count = repeat 10000000, observable_read
                percentage = observable_count/normal_count * 100
                console.log "#{percentage.toFixed(2)}% of normal object's speed"

            it 'should be comparable for writes', ->

                for a in [0...5]
                    observable_object.on.change ->

                normal_count = repeat 5000000, normal_write
                observable_count = repeat 5000000, observable_write
                percentage = observable_count/normal_count * 100
                console.log "#{percentage.toFixed(2)}% of normal object's speed"