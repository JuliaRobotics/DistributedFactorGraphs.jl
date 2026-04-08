"""
    $(SIGNATURES)
Add variable solver data, errors if it already exists.
"""
function addState! end

"""
    $(SIGNATURES)
Add variable `State`s by calling `addState!`.
NOTE: If an error occurs while adding one of the states, previously added states will not be rolled back.
"""
function addStates! end

"""
    $(SIGNATURES)
Get the variable `State` for a given state label.
"""
function getState end

"""
    $(SIGNATURES)
Get all the variable `State`s for a given variable label.
"""
function getStates end

"""
    $(SIGNATURES)
Merge the variable state to the variable if it exists, otherwise add it.

Related
mergeStates!
"""
function mergeState! end

"""
    $(SIGNATURES)
Merge variable states to the variable if they exist, otherwise add them.
"""
function mergeStates! end

"""
    $(SIGNATURES)
Delete the variable `State` by label, returns the number of deleted elements.
"""
function deleteState! end

"""
    $(SIGNATURES)
Delete variable `State`s by label, returns the number of deleted elements.
"""
function deleteStates! end

"""
    $(SIGNATURES)
List all the variable state labels.
"""
function listStates end

"""
    $(SIGNATURES)
True if the variable has a state with the given label.
"""
function hasState end

"""
    $(SIGNATURES)
"""
function copytoState! end
