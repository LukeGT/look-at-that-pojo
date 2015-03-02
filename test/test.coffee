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

        it 'should not fire more than once per tick', (done) ->

            count = 0

            pojo.on.change -> count++

            pojo.one = 'one'
            pojo.two = 'two'
            pojo.three = 'three'

            setTimeout ->
                count.should.equal 1
                done()

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

    describe 'configuring the library', ->

        new_look = null

        beforeEach ->
            new_look = look_at_that.configure
                debug: true
                random: 123

        it 'supports a debug option', ->
            new_look({}).common.config.debug.should.be.true

        it 'should not affect the original function', ->
            expect(look_at_that({}).common).not.to.exist

        it 'should inherit configurations correctly', ->
            pojo = new_look one: two: 'three'
            pojo.one.common.config.debug.should.be.true

        it 'should allow descendant configurations', ->

            newer_look = new_look.configure random: 'abc'

            pojo = newer_look {}
            pojo.common.config.debug.should.be.true
            pojo.common.config.random.should.equal 'abc'

    describe 'removing an object change event', ->

        it 'should not trigger', ->

            delete_me = pojo.on.change ->
                throw new Error("I should not have run")

            delete_me()
            pojo.one = 'one'

        it 'should still trigger other events attached to the same change', (done) ->

            count = 0

            pojo.on.change -> count++
            delete_me = pojo.on.change -> count++
            pojo.on.change -> count++

            delete_me()

            pojo.one = 'one'

            setTimeout ->
                count.should.equal 2
                done()

    describe 'removing a key change event', ->

        it 'should not trigger', ->

            delete_me = pojo.on.change 'one', ->
                throw new Error("I should not have run")

            delete_me()
            pojo.one = 'one'

        it 'should still trigger other events attached to the same change', (done) ->

            count = 0

            pojo.on.change 'one', -> count++
            delete_me = pojo.on.change 'one', -> count++
            pojo.on.change 'one', -> count++

            delete_me()

            pojo.one = 'one'

            setTimeout ->
                count.should.equal 2
                done()

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

        it 'should result in an observable object', (done) ->

            count = 0
            pojo.on.change -> count++

            pojo.three = {
                eight: 8
                nine: 9
                ten:
                    eleven: 11
                    twelve: 12
            }

            setTimeout ->
                pojo.three.eight = 'eight'

                setTimeout ->
                    count.should.equal 2
                    done()

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

            afterEach (done) ->

                setTimeout ->
                    changed.should.be.true
                    done()

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

    describe 'with observables in observables', ->

        other_pojo = null

        beforeEach ->

            other_pojo = look_at_that {
                other: 'pojo'
            }

            pojo.one = other_pojo

        it 'should be stored by reference', ->

            pojo.one.should.equal other_pojo

        it 'bubbles internal changes', (done) ->

            pojo.on.change -> done()
            pojo.one.other = 1

        it 'delivers changes to both objects', (done) ->

            count = 0

            pojo.on.change -> count++
            other_pojo.on.change -> count++

            pojo.one.other = {
                some: 'object'
            }

            setTimeout ->
                count.should.equal 2
                pojo.one.other.should.equal other_pojo.other
                done()

    describe 'with deep objects', ->

        it 'should allow me to deep set an object and see nested change events', (done) ->

            pojo.three.six.on.change 'seven', -> done()

            pojo.set.deeply {
                three:
                    six:
                        seven: 'seven'
            }

        it 'should not trigger a change when a non-Object is passed in', ->

            pojo.three.on.change -> throw new Error 'deep change triggered mistakenly'
            pojo.three.set.deeply 3

        it 'should instrument new properties of an object', (done) ->

            pojo.set.deeply {
                new_property: 5
            }

            pojo.on.change -> done()
            pojo.new_property = 10

        it 'should instrument new properties of an object even if they are deep themselves', (done) ->

            pojo.set.deeply {
                new_property:
                    key: 'value'
            }

            pojo.new_property.on.change -> done()
            pojo.new_property.key = 'something else'
