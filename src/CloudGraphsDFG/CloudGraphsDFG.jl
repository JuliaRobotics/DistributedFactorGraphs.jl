using Neo4j
using Base64

# Entities
include("entities/CloudGraphsDFG.jl")
include("entities/CGStructure.jl")

# Services
include("services/CommonFunctions.jl")
include("services/CGStructure.jl")
include("services/CloudGraphsDFG.jl")

# Exports
export Neo4jInstance, CloudGraphsDFG

# Additional exports for CGStructure
export copySession!
# Please be careful with these
# With great power comes great "Oh crap, I deleted everything..."
export clearSession!!, clearRobot!!, clearUser!!
export createSession, createRobot, createUser, createDfgSessionIfNotExist
export existsSession, existsRobot, existsUser
export getSession, getRobot, getUser
export updateSession, updateRobot, updateUser
export lsSessions, lsRobots, lsUsers
