
watch = (object, parent) ->

    unless object instanceof Object
        return object

    common = {
        parent: parent
    }

    return if object.constructor is Object
        setup_object object, common

    else if object.constructor is Array
        setup_array object, common

    else
        object

setup_common = (object, common) ->

    common.object_change_callbacks = []

    ### set(key, value)
        allows the user to set a property that could not be instrumented otherwise. 
        e.g. a new object property or an array index
    ###
    common.set = (key, value) ->

        result = common.set.silently key, value
        common.trigger.change()

        return result

    common.set.silently = (key, value) ->
        common.underlying_data[key] = watch value, common.observable

    common.on = {}

    ### on.change(callback)
        allows the user to register a callback against changes to the current object
        Calls 'callback' every time the current object sees a change within it
        (key, callback) ->
    ###
    common.on.change = (callback) ->
        common.object_change_callbacks.push callback
        return -> remove_from_list common.object_change_callbacks, callback

    common.trigger = {}

    ### trigger.change()
        Triggers the callbacks associated with the current object
    ###
    common.trigger.change = ->

        for callback in common.object_change_callbacks
            callback.call common.observable, common.observable

        common.parent?.trigger.change()

setup_object = (object, common) ->

    setup_common object, common

    common.observable = {}
    common.underlying_data = {}
    common.key_change_callbacks = {}

    common.setup = (key) ->

        return if common.key_change_callbacks[key]?

        common.key_change_callbacks[key] = []

        Object.defineProperty common.observable, key, {

            get: -> common.underlying_data[key]
            set: (data) ->
                common.set key, data

            enumerable: true
        }

    for key, value of object
        common.set.silently key, value
        common.setup key

    do (silently = common.set.silently) ->

        common.set = (key, value) ->
            
            common.setup key
            result = common.set.silently key, value
            common.trigger.change key

            return result

        common.set.silently = silently
    
    ### on.change(key, callback)
        Calls 'callback' every time the key 'key' is changed on the current object
        If 'key' does not exist within the observable POJO, it is registered
    ###
    do (old = common.on.change) -> common.on.change = (key, callback) ->

        if arguments.length == 1
            old key

        else
            common.setup key
            common.key_change_callbacks[key].push callback

            return -> remove_from_list common.key_change_callbacks[key], callback

    ### trigger.change(key)
        Triggers the callbacks associated with the current object's key 'key'
    ###
    do (old = common.trigger.change) -> common.trigger.change = (key) ->

        if arguments.length == 1

            unless common.key_change_callbacks[key]?
                throw new Error("key '${key}' does not exist")

            for callback in common.key_change_callbacks[key]
                callback.call common.observable, common.underlying_data[key], common.observable

        old()

    return instrument_object common

setup_array = (array, common) ->

    setup_common array, common

    common.observable = []

    common.set.silently = (key, value) ->
        common.observable[key] = watch value, common.observable

    for value, index in array
        common.set.silently index, value

    for method in [ 'pop', 'push', 'reverse', 'shift', 'unshift', 'splice', 'sort' ]

        Object.defineProperty common.observable, method, value: do (method) -> ->
            common.trigger.change()
            Array.prototype[method].apply common.observable, arguments

    return instrument_object common

instrument_object = (common) ->

    for method in [ 'set', 'on', 'trigger' ]
        Object.defineProperty common.observable, method, value: common[method]

    return common.observable

remove_from_list = (list, item) ->
    list.splice list.indexOf(item), 1

### watch(object)
    Takes in a POJO and makes it observable
###
module.exports = (pojo) -> watch pojo