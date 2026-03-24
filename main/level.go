components {
  id: "level"
  component: "/main/level.script"
}
components {
  id: "gui"
  component: "/main/level.gui"
}
embedded_components {
  id: "brickfactory"
  type: "collectionfactory"
  data: "prototype: \"/main/brick/brick.collection\"\n"
  ""
}
