fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'rex-cooking'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/client.lua',
    'client/npcs.lua'
}

server_scripts {
    'server/server.lua',
    'server/versionchecker.lua'
}

dependencies {
    'rsg-core',
    'ox_lib',
}

files {
  'locales/*.json'
}

exports {
  -- Client exports
  'OpenCookingMenu',
  'IsNearCookingLocation',
  'GetCookingLocations',
  'GetCookingRecipes',
  'GetCookingCategories',
  'GetRecipeByItem',
  'GetRecipeIngredients'
}

server_exports {
  -- Server exports
  'CheckPlayerIngredients',
  'GetPlayerCookingXP',
  'GivePlayerCookingXP',
  'ProcessCooking',
  'GetCookingRecipes',
  'GetCookingLocations',
  'CanCookItem',
  'AddCustomRecipe',
  -- Job-based cooking exports
  'CheckPlayerJob',
  'GetPlayerJob',
  'GetRecipeJobRequirement',
  'GetRecipesByJob',
  'ProcessCookingWithJobCheck'
}

lua54 'yes'
