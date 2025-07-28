local starterCards = {
  {
    name = "Guru Meditation",
    cost = 1,
    playEffect = { type = "progress", amount = 1 },
    destructorEffect = { type = "threat", amount = 1 }
  },
  {
    name = "Oops",
    cost = 2,
    playEffect = { type = "progress", amount = 2 },
    destructorEffect = { type = "threat", amount = 2 }
  },
  {
    name = "Dangling Pointer",
    cost = 1,
    playEffect = { type = "threat", amount = -1 },
    destructorEffect = { type = "threat", amount = 1 }
  },
  {
    name = "Garbage Collection",
    cost = 2,
    playEffect = { type = "threat", amount = -2 },
    destructorEffect = { type = "progress", amount = -1 }
  },
  {
    name = "Canaries",
    cost = 1,
    playEffect = { type = "threat", amount = -1 },
    destructorEffect = { type = "threat", amount = 2 }
  },
  {
    name = "Heap Spray",
    cost = 3,
    playEffect = { type = "progress", amount = 3 },
    destructorEffect = { type = "threat", amount = 3 }
  },
  {
    name = "Superoptimization",
    cost = 2,
    playEffect = { type = "progress", amount = 2 },
    destructorEffect = { type = "progress", amount = -1 }
  },
  {
    name = "Tree Shaking",
    cost = 1,
    playEffect = { type = "threat", amount = -1 },
    destructorEffect = { type = "progress", amount = -1 }
  },
  {
    name = "Memory Leak",
    cost = 2,
    playEffect = { type = "threat", amount = -2 },
    destructorEffect = { type = "progress", amount = -2 }
  },
  {
    name = "Segmentation Fault",
    cost = 3,
    playEffect = { type = "progress", amount = 3 },
    destructorEffect = { type = "threat", amount = 4 }
  },
}

return starterCards