    
watch = (object, parent) ->

    unless object instanceof Object
        return object

    if object instanceof Array
        console.error "WARNING: Arrays not supported"
        return object

    underlying_data = {}
    observable = {}
    object_change_callbacks = []
    key_change_callbacks = {}

    fire_key_change_callbacks = (key, data) ->
        for callback in key_change_callbacks[key]
            callback.call observable, data, observable

    fire_object_change_callbacks = ->
        for callback in object_change_callbacks
            callback.call observable, observable

    setup = (key) ->

        key_change_callbacks[key] ?= []

        return if Object.getOwnPropertyDescriptor observable, key

        Object.defineProperty observable, key, {

            get: ->
                underlying_data[key]

            set: (data) ->

                underlying_data[key] = watch data, observable

                fire_key_change_callbacks(key, data)
                fire_object_change_callbacks()
                parent?.trigger.change()

            enumerable: true
        }

    for key, value of object
        underlying_data[key] = watch value, observable
        setup key

    
    Object.defineProperty observable, 'set', {

        ### set(key, value)
            allows the user to set a property that did not exist in the original POJO
        ###
        value: (key, value) ->

            unless arguments.length == 2
                throw new Error("set takes exactly 2 arguments")

            setup key
            observable[key] = value
    }

    Object.defineProperty observable, 'on', {

        value: {

            ### on.change(...)
                allows the user to register a callback against changes to the current object
                (callback) ->
                    Calls 'callback' every time the current object sees a change within it
                (key, callback) ->
                    Calls 'callback' every time the key 'key' is changed on the current object
                    If 'key' does not exist within the observable POJO, it is registered
            ###
            change: ->

                if arguments.length == 1

                    [ callback ] = arguments

                    object_change_callbacks.push callback

                else if arguments.length == 2

                    [ key, callback ] = arguments

                    setup key
                    key_change_callbacks[key].push callback

                else
                    throw new Error("on.change must take 1 or 2 arguments")
        }
    }

    Object.defineProperty observable, 'trigger', {

        value: {

            ### trigger.change(...)
                ->
                    Triggers the callbacks associated with the current object
                (key) ->
                    Triggers the callbacks associated with the current object's key 'key'
            ###
            change: (key) ->

                if arguments.length == 1

                    unless key_change_callbacks[key]?
                        throw new Error("key '${key}' does not exist")

                    fire_key_change_callbacks(key, underlying_data[key])

                if arguments.length <= 1
                    fire_object_change_callbacks()
                    parent?.trigger.change()

                else
                    throw new Error("trigger.change must take no more than 1 argument")
        }
    }

    return observable
    
### watch(object)
    Takes in a POJO and makes it observable
###
module.exports.watch = (pojo) ->
    watch pojo

obj = watch {
    one: 1
    two: 2
    three: {
        four: 4
        five: 5
    }
    six: [1, 2, 3, 4, 5, 6]
}

console.log 'Listing properties'
console.log obj
for a of obj
    console.log a

console.log JSON.stringify(obj)

obj.on.change ->
    console.log 'EVERYTHING HAS CHANGED'
obj.on.change 'one', (data) ->
    console.log 'one changd to: ' + data
obj.on.change 'one', (data) ->
    console.log 'did you hear me? it changed to: ' + data

obj.one = 'one'
console.log JSON.stringify(obj)

obj.three.on.change (data) ->
    console.log 'something in three changed'
obj.three.on.change 'four', (data) ->
    console.log 'and four changed to: ' + data

obj.three.four = 'four'
console.log JSON.stringify(obj)

obj.three.on.change 'seven', (data) ->
    console.log 'a new number seven changed to ' + data

obj.three.seven = 'seven'
console.log JSON.stringify(obj)

obj.three.set('eight', 'eight')
console.log JSON.stringify(obj)

obj.six.push 7
console.log JSON.stringify(obj)
