'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "45bf8576144c3142ea05a044f4f4d065",
".git/config": "4fcddfb48d06fb0dba7e3937705acbbc",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/git_backup/COMMIT_EDITMSG": "898cc34cb51ff620ff95a9f07f11f61a",
".git/git_backup/config": "4fcddfb48d06fb0dba7e3937705acbbc",
".git/git_backup/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/git_backup/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/git_backup/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/git_backup/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/git_backup/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/git_backup/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/git_backup/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/git_backup/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/git_backup/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/git_backup/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/git_backup/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/git_backup/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/git_backup/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/git_backup/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/git_backup/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/git_backup/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/git_backup/index": "353d34030d4718a9f3657c62cdb9d7c5",
".git/git_backup/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/git_backup/logs/HEAD": "7274d8afe752075fe2400880f2e2fca8",
".git/git_backup/logs/refs/heads/main": "1e80ff4a690e246a7eb6fde7139f4e61",
".git/git_backup/logs/refs/remotes/origin/main": "8c0222fc96e67e0e2f65a4eacc13a011",
".git/git_backup/objects/01/90b0670693083a345467816264f7a052ed277a": "96c6c33a3e211e3f2c0f5babbf4ed063",
".git/git_backup/objects/01/ae5de01a94efa0df5847f3b4b2fa15aba98c98": "2aece61660165cf672e8d022c36a702b",
".git/git_backup/objects/02/1d4f3579879a4ac147edbbd8ac2d91e2bc7323": "9e9721befbee4797263ad5370cd904ff",
".git/git_backup/objects/02/909e2b69580d0a9f60f11476e87cbe64af9578": "ae88ab25d5c9b0664998b23fe0253a22",
".git/git_backup/objects/03/354559d754f448d068522d8e55b8e363495afc": "fbd8843f721eef2d3fec08957eb0e657",
".git/git_backup/objects/03/74d40b64cb1f1ba3e9ce3c0bbffd25d08c9f68": "aecab20214f7d73b32fa9b9948509e5b",
".git/git_backup/objects/08/29ce24f197c9e71fa0d3774e1ac8891d70db61": "75fd148aa03c3067c11355ca3607bb89",
".git/git_backup/objects/08/f53374bba8d5f8b35f16a4baf5987f3ca7584e": "aeb56b38a746ca8ea900a5e4a70b031f",
".git/git_backup/objects/09/44fa02de5a15ea347ed99aad09313112a2d30c": "0f6cb93a3b5c83175b50e64e222db022",
".git/git_backup/objects/09/d268341c144916a2ecc0dfeab7aee8d0109545": "1b64ff4daa8389b88ee97eca446c5494",
".git/git_backup/objects/0b/0bc05e3cbe96cb06ace24c1d4c04005aae6369": "5e68e8afa41b780c66265d1083e604ea",
".git/git_backup/objects/0c/7eea155af084c761924181e3cefde48309c7f1": "06c2f7a254f8d2ddf81d962a7c3dffad",
".git/git_backup/objects/0c/81f1322a19b14a67a8a20984234310e8461578": "a5a84f1a2453d046aff3d48c18285057",
".git/git_backup/objects/0d/7a627ca8e92e5ddac395a1fa1f6ebed8192a21": "038dae8c46bb475670c12c9beb31f810",
".git/git_backup/objects/0f/2fbe3f668f8b482bf7ffb781203d9df2643c46": "758e8caa0dda146f4b2dd0ed1733e7b1",
".git/git_backup/objects/0f/44c66f98fcc699a43781ae5ef751770af93603": "92b8544acd372efed39aab80c791de2b",
".git/git_backup/objects/11/cb5ea64833c7c9cd0c03be4c9df71db4de3674": "d4ffd51ed86ff3bfb7537a981ae5d8cb",
".git/git_backup/objects/12/d0b2599441a400dd18f0214f4c72bdaa000192": "3c59c79e418ed72c1d8df7d383bd670f",
".git/git_backup/objects/12/d5798d4eddf1bfa40342cb630fdc13258368c6": "e3f5dd5911350efc3c49ad02160d1a36",
".git/git_backup/objects/13/05927fa9e0ce6e04b3186a252b4bfb7cab5ba1": "f1df8a1f9ab78e5a0f81d1c02746eea5",
".git/git_backup/objects/13/0a54df412615510e14897aad422901ee98a12e": "1ed8afc54b4fe8df4cd7ec24b3e7596e",
".git/git_backup/objects/13/10300a3af9082838d72b22079520b81fd111b6": "a165eff43487ff89a2142b416eba0624",
".git/git_backup/objects/17/0ae8bea94c5da46c6f3373a9807eb48c84aa74": "feaa445e57e7770f2037733d05669644",
".git/git_backup/objects/18/6bf5714ef1c261b2c322c460aecda9dae7278b": "540fbede1688c92fb11bd5289e57557c",
".git/git_backup/objects/19/1113e5eb4038f908f77ef96045607ced5e01b2": "67858ea0d05c01665d92085c650e5e1b",
".git/git_backup/objects/19/ceacd38f8fb445236ed358d45e69ac2cd3fb8c": "55bf93e011d9c8541f4de740102b6f28",
".git/git_backup/objects/1a/3b225db4afd6c4f743bfabfa5aa2b30feb820a": "8ec15525d1121d9ea0a8f3d50cd856b1",
".git/git_backup/objects/1f/42d88ada268467ef8a14148ab66e636798453d": "bc4d42d5f9e95c498a7b99c6d1e708cf",
".git/git_backup/objects/1f/b714104e922376aa4ee2d9860bbdd485f1826f": "43533a8f3a0c5ff384da6b1597818b01",
".git/git_backup/objects/20/3a3ff5cc524ede7e585dff54454bd63a1b0f36": "4b23a88a964550066839c18c1b5c461e",
".git/git_backup/objects/23/c828401c021f1f12ac38d432cd2cd83ca64455": "73fcf49ae2cf71155ad8d31133de689d",
".git/git_backup/objects/24/61c3a3256c346ef3d42d412f6f3ff08158bc52": "289a14dea56c23925a4fbb3d9311ba5e",
".git/git_backup/objects/26/1dcffad3b49628b7ff6d59575f3906ce59294f": "102709ec268b4ee4929afdfa6e26273d",
".git/git_backup/objects/26/5cdc752132241e0f2307e8cd70d39b99cdd473": "8e3ffae9c8a1fe1fe017deab71d25ad0",
".git/git_backup/objects/27/85401a88d234b96b735d0120c54208daa346da": "f633ad3f90a50bdd2166db9b672edbf1",
".git/git_backup/objects/27/c5a2d8808551dbd1dee164b6d906322f6ae887": "e7f242844c9cfc3d9bb7e47eb6dc6ed7",
".git/git_backup/objects/28/7a7ec4cdb7135aa5c35f9b7db9112e3e7d5c92": "ced8a4ded2a8da06af728670ba8ae50d",
".git/git_backup/objects/28/e83a7eb3934ed1fb802cb76b9e2cc74818927f": "af16346d98d973cd634a4b6a55f08732",
".git/git_backup/objects/29/34a3639d8e588c231df7e7d3ec203f90532856": "a17d81e9c8ac1bf9a36a54b34303d426",
".git/git_backup/objects/29/f22f56f0c9903bf90b2a78ef505b36d89a9725": "e85914d97d264694217ae7558d414e81",
".git/git_backup/objects/2a/9165cb126bbaf5ae583640eed30c2dbbceab60": "1d20391defe553fdf36806752c6f9600",
".git/git_backup/objects/2c/36bf298a649a2edc826a7c4b1ec82cb0c4c47b": "709b15998b126c070deb092927827059",
".git/git_backup/objects/2d/216cdd90313cb4d391abc89386bae3f65bc660": "3b1ba3f2a3cdfee7671b0c5df3f8f86e",
".git/git_backup/objects/2d/eb84ea7a44f43eafbfc41e7ed9e0890df75d05": "6576560ea8d3ee61c920303ff8bb732f",
".git/git_backup/objects/2e/f9cf26d548966db9967949e75b5fc4d921f0e2": "04cc955487714ac4c2226a1a12cf3cd3",
".git/git_backup/objects/2f/792cf3e08f859a59085df50fd36cd318459aec": "7a276e2647b8725b4e97c3a464d586fa",
".git/git_backup/objects/31/25e82f132403184418a06fb2e8a22d78151ce7": "0fde801d492e616e162b0ba2547b59aa",
".git/git_backup/objects/31/53a7e058b1b8b0d8a5269af7963e537e177f95": "8db52aead678443c77db5aba77ffb489",
".git/git_backup/objects/32/1a77a2f22915abf055e99f0287f894034fdf54": "69b415c93009ce4446d186b55ffc90ba",
".git/git_backup/objects/32/e9feb0db46e717fba01d4561b8446863a16fc6": "da9e355838a06516aa8d37e45dc3f63c",
".git/git_backup/objects/33/7be342eea29bacf5810718703f5648c4410772": "9d0adccd301dbf6a0748289d15523f31",
".git/git_backup/objects/34/87740e6d4661ea3e360bf5947240e685ad304a": "7d0c29cae176df9c45ad0cb7a1c34f38",
".git/git_backup/objects/36/c6eda9f66fb26f819a2d09cd56c9e40bd1bbfa": "321db2894b606ca90e6551b98ed4d89b",
".git/git_backup/objects/37/17b71eaae9c7d90b257c8c0fa88a8a1a908efc": "55b2e07b03752eb637afb0d10ec5007c",
".git/git_backup/objects/38/f05fd9fdc83963932f5c3248297aaa07103137": "570484ead26a6025398d8e38e83a65bd",
".git/git_backup/objects/39/741d6ce80a74de30563071c50f8bfa702f5525": "4e51a3aadbbf2d846a256f154665309f",
".git/git_backup/objects/3c/9bafa9b68a6048e5029f5ed790d0c1a51f8fae": "1b9ce335ed2a1c9a98629d8f18f69db0",
".git/git_backup/objects/3c/cbb65f9913c5c01760e5d791631828b7523bf8": "2c31ebea74618b27910128653ac691c6",
".git/git_backup/objects/3e/bb1203ec9462d0b37a37f55aeb2af765b099f5": "6b7de00b5e59919832b0137473b10c77",
".git/git_backup/objects/43/b243d86a6123a5131ea1fd7012755de1010aa8": "c656b4fd56cc122022cbfaa97264fec8",
".git/git_backup/objects/43/b8651aad72b21af8cab2b6d0e9ac7dd52344e0": "7896e48f6ba01dd93af8e9e250238148",
".git/git_backup/objects/44/5d0120fa779ed71cc1c36901ee9fc2f36117ef": "46a4bcd256af1f2725f64b0dd4047b85",
".git/git_backup/objects/44/61f695333e77f3152472eed2712cc7c2edd402": "f86f89547ee047ba1e9994588f276cf5",
".git/git_backup/objects/44/ff6c8e5e1bf37841a85fdff1f2537872a4295e": "59c474ac1e8938230017788b80b1901f",
".git/git_backup/objects/45/d18be5df2ef036a2fa17fcf4f27e60951b4ea6": "3304cac5074848eae5e5443ccb8fa17d",
".git/git_backup/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/git_backup/objects/46/cc1ffd056476cb899772df183014c237261dd8": "7366ab8a2486ee7b646cae3f473c8fbd",
".git/git_backup/objects/47/a02a5d2b41357a3eed179dfa94891da9684e18": "6bc8c224cbdc2ca8cee3a6e10745bfd2",
".git/git_backup/objects/47/a314d063a16a5a722e0d55c9c16a1f7e30be4d": "a8fd4a9f7ef16fa176fab205173b0584",
".git/git_backup/objects/47/e6b3c4d13f28d1ced91ddd5ebb1136fc0ff1ef": "b3b3aeb63b5979c312aed83d5b54aef5",
".git/git_backup/objects/4a/745e04e53857313f6aea34405dba32eac1385e": "70c4a2c60bba9e29e4061c1be9e7235c",
".git/git_backup/objects/4c/f141ea2c6a6134b86f9e263f6ef4c99ae1691a": "9810226d41cefdb7285fc49fbcfd9908",
".git/git_backup/objects/4d/bf9da7bcce5387354fe394985b98ebae39df43": "534c022f4a0845274cbd61ff6c9c9c33",
".git/git_backup/objects/4e/1efc732eb80e14d68ceb63e5ccfbef793aeb2d": "3438ea4de8808ceeee55e41de91f63f8",
".git/git_backup/objects/4f/fbe6ec4693664cb4ff395edf3d949bd4607391": "2beb9ca6c799e0ff64e0ad79f9e55e69",
".git/git_backup/objects/50/168aca2a2d9c43798201eaf41286dca64fe946": "8d349bc7afe5da8dd8cfceb2353a8bd8",
".git/git_backup/objects/50/1bbcc15a9c30d2f5ee10e31c74842ac1596de2": "733d58ceed05f5f6816cd561ee8fc893",
".git/git_backup/objects/52/2e5b9453782cd1260a8a4f7979e40c65c1ac62": "30d0e14e1fca96b3679808296d2ed601",
".git/git_backup/objects/52/9b85336e5b4c19e744d4876be9e3c4cdef886b": "df604164015ae221bd67fcabfdab52bb",
".git/git_backup/objects/55/226b9f917742cbc9ef56cb7bc3712477458db4": "6c427e464d3d90ec3d2d8d1c47b0b302",
".git/git_backup/objects/56/30f1239fca9384e6cd4a8ba8025967c3bbe82d": "60bfb5bd52d566bea440add0b921c3b4",
".git/git_backup/objects/58/cd5e0d2b5f5d6c9bdd63a1318fa12d79311df8": "5562219ce790c02c083f6fe1b168bdc6",
".git/git_backup/objects/59/390e09a37851fd145ba9539f9efbcc352aa5c6": "fc8caf3f9eca9438d5e14c2fb0435db1",
".git/git_backup/objects/5b/8ef6b8ded8726320ab726fe4f4982990e8185f": "5727add066833320be6c3feb678bfe4a",
".git/git_backup/objects/5c/4b0aaaad8e948468fd65e2deb2307f25b028a7": "c8f2182eb691241bc3cca9e82d33a378",
".git/git_backup/objects/5c/614bc108c19a03f17520eff14d0a6d0ec29590": "d8fb124eda9370a9144d4d07939fe685",
".git/git_backup/objects/5c/9079e2cde4b48dd8687fb04e5fcaa1ff6e7bc2": "5956cf483f9cf4373d0b4e69cf989f92",
".git/git_backup/objects/61/0dd252da547db3d681803414daa28739a5e13a": "8336615fe1708db6c1ee7fbf47646fdb",
".git/git_backup/objects/61/0fa26a0bc360449a84a3ec6a023bb40628c136": "c548c08bfab95ba782622845beede305",
".git/git_backup/objects/61/5a56bbd29af4f28ca343a426f3710172f81d8f": "5e34285bf5d6fbc26b78b31358eeefec",
".git/git_backup/objects/61/86fa5ded6d629684efd15d74c7eda23840b4e5": "c28a708d99937195bf28611a233d92ac",
".git/git_backup/objects/68/5f3180ffa2f6aaeccc6b9822fa1e5edf8c569c": "6aad0ffc9a82b65918395bbaaa0a3e81",
".git/git_backup/objects/68/a183bff0fcf85bff174ae8ab3962f56c132e67": "b46c06499d9cda6d4871a1014517e0f5",
".git/git_backup/objects/69/6c025a20e87a5d52aac62db5336221388ef9c0": "cb9bac6fee64c34e0824e1722183c207",
".git/git_backup/objects/69/7f9f0633c2c94f97b2517e3e8dce9334b6612c": "b57ba7739feeb1751c3f5c7e6ead2dca",
".git/git_backup/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/git_backup/objects/6c/10618f805920ea04da673525b9565055ee0f57": "3d4ca832ce492f324caf5fbed79d65ba",
".git/git_backup/objects/70/0072e8df9b2f5867e16d7a0f446758649a6b4c": "8965a130a829c5ed7f386286f0354e5e",
".git/git_backup/objects/70/f7f33066fc0e252f0701a0142b1c2a76ff10d1": "5308d686c8473878a01b7e63ca00a996",
".git/git_backup/objects/71/9171a4ec2cb66af3711929e8529edf4d561e89": "d768a564ced4cc6fdbd23d4983c66316",
".git/git_backup/objects/72/aaf2ed2852909fb23fc77052b2d9388ab336f3": "73546b49b0babb28e605136d2f13d52b",
".git/git_backup/objects/73/471fc72f394ba136f5ba9148454531851108fe": "efd51e4e7f090fabcd3d9bd69a503773",
".git/git_backup/objects/74/7d80887ed7dba1f900d6a0a0bb10d9dcb3a725": "5299c4a063f98d75cf9250d57de8f676",
".git/git_backup/objects/74/ad3fcea247c0380cb9dbc1c98b0241c8b13db4": "25c86393c067e565113147e63976a96b",
".git/git_backup/objects/74/ff73d08bea88619e31e42a4df5674026dac89f": "03d2a2c922e195e696a67bb1a62a85af",
".git/git_backup/objects/78/0fc35d2a50dd9a6e2d9f12f927a8273ff87c5d": "19bc78c9e88d8b65bb1e1ffccd43a22d",
".git/git_backup/objects/78/6cdce93c338b59668a5d53c14210a057fe49a0": "01e64d67b15aa63f0dffd1c73d2fbe72",
".git/git_backup/objects/7a/6c1911dddaea52e2dbffc15e45e428ec9a9915": "f1dee6885dc6f71f357a8e825bda0286",
".git/git_backup/objects/7b/1f99c3c293fb85b643def10619ce2151cbc50c": "4e0aafc6b4d549035f563ad85c37b096",
".git/git_backup/objects/7b/eb02a6d9baeaa38e7bffdd9d90b11872f36fb0": "716f8847713ae79445d6fcfcfd85e114",
".git/git_backup/objects/7c/818ae2bd438901de5a39d4b7385a5a4820478c": "adbe5ae2f2c8e9b74b0fdfb07524b82b",
".git/git_backup/objects/7d/cb982124b091cda0c0d5528fae87e5a9d42468": "2d707510e7c7751bf680195fd79ff124",
".git/git_backup/objects/7e/7cb5b1223aa849241a48a1f7bd1b2c5bf5dc44": "8bfe5cc02f6881804900627a5024af53",
".git/git_backup/objects/7f/90940c244f7cde4b62f7aa818a64c733238282": "126eacf28c0b755d8e4bb2f382335c09",
".git/git_backup/objects/7f/ddc9084174f8c35c81991a85f42c83ead949c9": "0e0da92ce6dea2d2640c31c3a7623ac9",
".git/git_backup/objects/81/8c4a80d5632cd97659c2458d86da619bf3c566": "958e115bcf13488d2d328270c8944147",
".git/git_backup/objects/85/6da8d9c195817812fbc374f93f5aceb4c847b2": "fc398961d6ee1e9c3adc24d5ad62e020",
".git/git_backup/objects/87/6909d9447afa56827d89a86cd03eac7cb0fd62": "6e48db137d1a07b1d12b2a54bef5d393",
".git/git_backup/objects/87/bb1d5c79f5430cc88a4f25b9b326fab1d5855b": "95f7b7d5c0e8571a540c32995aab5ebd",
".git/git_backup/objects/88/98c3fc732e2ee3f4153417f1645bd7b79e7400": "ed29cb16c4ce03c3c660076d7aa46b9e",
".git/git_backup/objects/89/a000e4f4ade79c2bf7b37b5b9e8f44a80cb714": "e6e709ebfd8d830c176af5465d0af9c3",
".git/git_backup/objects/8b/59d29b9f1e5f4bbf145a917321e27447e0c589": "a2272f2152f8b3b619d327ed9a4252e2",
".git/git_backup/objects/8b/a9e445b2dc9d6560f716c8ee0e4765fdfeb525": "7873f7eb691315d2e068209bb7438e27",
".git/git_backup/objects/8c/9f08b8d9f4817e3527aed8a6137ac10fc90fea": "0e7905b3d45e612b67144e9cbaadf7d4",
".git/git_backup/objects/8d/f131decc12699ecf178c2e5e72f981ad020b54": "7cb193ead370ef39c93f7317590012ea",
".git/git_backup/objects/8f/9294b6eb82af90900a24c055ed854e8bf7c09f": "d68d66d180ee8ee7e29f345dcc765d1e",
".git/git_backup/objects/8f/ff8ad5dbd8fefc66e549d8edc6bacf371d841e": "6415ea8d64ea6a16ada9b48ea1663ba8",
".git/git_backup/objects/91/a3d93114fee20d98bdcf72cb566d3303c1a038": "d9ce0b4986600a28163ef9bc01ecf97f",
".git/git_backup/objects/92/63b6cb891d150d4f55a390cccc64aea6685372": "73267a5155dbe131b3143fa1d9109c1c",
".git/git_backup/objects/93/46db2aac6b08d799ed92cdaf24a063dba815ba": "75dd8c07689884b33084b9135790b985",
".git/git_backup/objects/94/b53972ae76e7879cdeb2c3a0b5f1e2cc0f6257": "90c1e3c987b77408b65264370a26e775",
".git/git_backup/objects/95/a1c97d5aed5984cc0f0f0534eed1f34559e097": "8fb43a7a3b9dc75b23142094c637c7f6",
".git/git_backup/objects/96/31ff8ef858a1b22a56d65239d28d42a460930b": "eb6db503feb4135a8f34b7a18127023b",
".git/git_backup/objects/96/eb9606e9418066efb2af3c42c5d74f9dd4f0a0": "be7c85f8e626a7be1ed98f9f022676e0",
".git/git_backup/objects/97/10ca823b333a75f38031c7da2d8115ba247059": "c383c1f7b9a3243098966904e0331e14",
".git/git_backup/objects/98/0d49437042d93ffa850a60d02cef584a35a85c": "8e18e4c1b6c83800103ff097cc222444",
".git/git_backup/objects/98/87f058857209bd931506ed814602a40a8cfe8b": "8b55d1cba7c1339ee1ff20d4f4a51e56",
".git/git_backup/objects/99/901cfbbac6b151a1ccd587a7e0698e21eb1b6a": "6d35835bf1a63e19d7362b179685f445",
".git/git_backup/objects/9a/a01ead5d0153d05b0000f529ef91c3aebd6d67": "55bbd6bba6d05303b14802a95e4bb772",
".git/git_backup/objects/9b/3ef5f169177a64f91eafe11e52b58c60db3df2": "91d370e4f73d42e0a622f3e44af9e7b1",
".git/git_backup/objects/9e/3b4630b3b8461ff43c272714e00bb47942263e": "accf36d08c0545fa02199021e5902d52",
".git/git_backup/objects/9e/52a2447e172f3527f76fbc575ae2a1614763ee": "d2ecff56075d0a55272de7d73b0c09b4",
".git/git_backup/objects/9e/ba3a0f16b4e9a93843d4b13c93e37bbca1b143": "6a49b5eebeb367ccf9c7c2f7e4964025",
".git/git_backup/objects/9e/ef637f810a201692899c15b51f80964d8e2454": "57f74f93c11f83f7fc98bd6aa7626a14",
".git/git_backup/objects/a0/81c1b40c5c2cfb16ef88f71fb147c464ab5345": "dc6f7bb0c9463fc024ea1443b2c0981f",
".git/git_backup/objects/a1/1668ba2add893c196cd0a5c46adfe501fdbffa": "bd3cde9d293655c0653eb0036cfaf77e",
".git/git_backup/objects/a3/cd4040e5a5047de16da8a0561e23bb1e1a1f10": "1a1d8fc7ff845dc23fbaac2d892df980",
".git/git_backup/objects/a4/32b6e2472277781578775ea1bf5f2f826459e1": "4f89719795dcedae948b20c6158dbcc0",
".git/git_backup/objects/a7/3da57803dda6193bb0bbf0f98c319adf1eac9d": "1bfbb41b119e5a4e7b1aba53085642c3",
".git/git_backup/objects/a7/a8848201dade78039202dc8dc739f80506e47c": "ee0657dcd557dee7ef157893f094622f",
".git/git_backup/objects/a8/b066862ca6bbfc0bd805047ecbb3e3e1d02ae0": "67f3cec65a2aee2453aeac10c5f3c1ba",
".git/git_backup/objects/aa/b30240b05bb2278c589c7c5ba41a02fbe17d73": "ea2461e0fffb0bb01a90d644d4f69497",
".git/git_backup/objects/ac/560d1523ce7f74c64009a3b43d28d422c02bd7": "c918a8b70adccea924f535955f129b83",
".git/git_backup/objects/ac/6a28184f1a2369dad68a021b008ce20ef4ab49": "cbe6604636f462b438c85ba204d9b1a7",
".git/git_backup/objects/ad/1cfa37a1f4e162a6732956fd9c0e88e7e3c018": "a5f7e8349902ffb5df85ad59737f8f54",
".git/git_backup/objects/ad/cdd8eba87e6055e44842cfd4a3f572c781141e": "ce1b031cf84b59dd0a4e46b87f9d7ee9",
".git/git_backup/objects/ae/15a6ac71e28dbcf70ef07aafc8f5427fcbf342": "2d5e06fb11c3da8d1b580fdf60cfeb31",
".git/git_backup/objects/af/472b149ac39f5e7798e23a5eb52743831c2464": "97f0a9000bca960b604111b383811fc4",
".git/git_backup/objects/b4/7c0a44a3ae9f1f5434f5c77a4ef622ddec7a58": "c9c1d69f47ade1d29ba16e15f6c52d09",
".git/git_backup/objects/b6/b8806f5f9d33389d53c2868e6ea1aca7445229": "b14016efdbcda10804235f3a45562bbf",
".git/git_backup/objects/b7/7e85ea717770aed8d29d47b3d08911a33607e8": "938b68eb7d906bf6d9e767c22cfe4ddf",
".git/git_backup/objects/b8/ae968788a881085972fb819616e63ed309789e": "52d231802427654a549afcc4af9e4aa3",
".git/git_backup/objects/b8/ce8f374088dfec6531debcfe2d83302566f942": "688f12bc6475458107d394ff0f7825a2",
".git/git_backup/objects/ba/22de39b213fb12caf0cdc63106263e7edae09f": "2579aac378e8331e30f677650864d56b",
".git/git_backup/objects/ba/6263aa7eaf38f02b53a9c81f1d29cdffc70ad6": "99f712eb0a4809ca8a2d58770495afda",
".git/git_backup/objects/bc/22b7cba8d94f446ab8ff6114e3d703e68f0a17": "3a9ad5ec7ff1dda6145de3258d8bb609",
".git/git_backup/objects/be/0c1bbdafdda0aa11a78fb886f80ee4b263b444": "4da085d489eb0de6468b4999492a99ec",
".git/git_backup/objects/be/adc4f25b34029657549ae3458849a370d0b68d": "3dfb4a97bbcdc7b4a8a0d8c420805f65",
".git/git_backup/objects/be/f46f12107e3211fd1c2c940eb02288914ee0a1": "44a9ea76a7888def3abd81d0e1772357",
".git/git_backup/objects/be/fe5f616d80d307ca98f961395f659f7a1466cb": "2b2a6278039e2d88f94b551aacef8f93",
".git/git_backup/objects/bf/666c775e07a55900e88b901ad96a1d3e5c84e3": "20f47eb4b2b3ac5c4b6d735636533c14",
".git/git_backup/objects/c0/01b9317820ca7af195653f1f236ed6548450c1": "4c3d089e6d5818da88e00ddae6103cf4",
".git/git_backup/objects/c0/8ddf4d911184983e04e1380333ed322dbd030a": "159f9760fd03a866ec39f64f47b79199",
".git/git_backup/objects/c4/016f7d68c0d70816a0c784867168ffa8f419e1": "fdf8b8a8484741e7a3a558ed9d22f21d",
".git/git_backup/objects/c7/e35da1092c19517ccede9b244aa86c2f25615d": "56773e8f47734c9af0723826eb7df333",
".git/git_backup/objects/ca/3a7bef1dcf6350d0e5faba4d5ac0afaa522ecf": "7303308a7b2ded6615878c1065a68e38",
".git/git_backup/objects/ca/3bba02c77c467ef18cffe2d4c857e003ad6d5d": "316e3d817e75cf7b1fd9b0226c088a43",
".git/git_backup/objects/cc/1d66564c9daeab13394ded42f56b03877f7780": "2a5c0185ed69c2dfe3560cb49a270759",
".git/git_backup/objects/cd/58a2650dc77cec0518f6f3dcb1e3ab762eb219": "ed3ec8aa323947e002b4f8ba1bdbde55",
".git/git_backup/objects/cd/dd03f559fd24639dd23e04dbc74834cf0e6334": "a627bbbf350f8f497362935826ec2c5e",
".git/git_backup/objects/cf/22ce6e9e7ebde567d2607951db345b0cbe0b24": "9461bb6b52576aed2d22268de00fd121",
".git/git_backup/objects/cf/a3ad2e247c9cc8a84066764e525d0e8b83988d": "dae48181e09430eec4c9e70bd50d9faf",
".git/git_backup/objects/d0/ce00838a94a316a062a84e5c65f2d887df3be4": "d279469db5025ef3f8ee9d2bf4835a9b",
".git/git_backup/objects/d1/d1524c272694b3296a9e453a89a3ae40db5c0d": "12ebcc161173dd270ff146651ddc2cab",
".git/git_backup/objects/d4/2f4cd632911ce3946d2a4554d20da3b32101ca": "c8e7a50aa613d7da5a06b4fbd8b9d610",
".git/git_backup/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/git_backup/objects/d4/c173c25758e946c8b4391e40d0996db2cb4572": "d6929c3e65b52d71846d2d8b30a2c1b9",
".git/git_backup/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/git_backup/objects/d8/1cffb2f4b078a27154171f88e36ad36f6327b4": "de0c2ad32f9858c7a2a178b5082c7970",
".git/git_backup/objects/d9/ad56692dac1b8762dacb2fc2347bc29b113778": "31c5c7a1cefd7abaa4c9a7a20afbb979",
".git/git_backup/objects/dc/ef1e23c0739df8ebca37d43263db4dd408ccf4": "67af9cbca61be0fabcf3efdec7e59779",
".git/git_backup/objects/dd/0b98e2a630639268d92e402e2c3e72eb6d6b8d": "c761ca226bbc90ffeef1131d06f5ed3d",
".git/git_backup/objects/dd/f0d69d07ca292db82eef16d27d9127d180a1bb": "6179d6384a9268080582f1543f9180b4",
".git/git_backup/objects/e1/4ef9593f5523d357dd1b8bce1f6f2cbe168592": "a50cb4bdd07733a9ff06921de83f10e7",
".git/git_backup/objects/e2/6f74f0258310dbc8f8becf4f8c3be1933f3bec": "a3a60b5ba0cc743fcbb4bfdd855d6832",
".git/git_backup/objects/e3/e9ee754c75ae07cc3d19f9b8c1e656cc4946a1": "14066365125dcce5aec8eb1454f0d127",
".git/git_backup/objects/e4/20168b76ae26d8ccdf705cad4d1a18419ae8bc": "ad3f12cb7e705e12a7f09c1471f88ae8",
".git/git_backup/objects/e5/1c377fe29b177e3a46ecc5596b164c2901f5a0": "aab96fe1599b7c245832af2345526041",
".git/git_backup/objects/e6/143bd58df53f65514e6a2062cff6e78a3adbb5": "37a8867d73bd2f504faa15d91c2bb370",
".git/git_backup/objects/e6/9de29bb2d1d6434b8b29ae775ad8c2e48c5391": "c70c34cbeefd40e7c0149b7a0c2c64c2",
".git/git_backup/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/git_backup/objects/e9/d84fbb34a5af0bf6baa16e243140c9ae072021": "324327fa18e6cdbfb3132bca9f32f2de",
".git/git_backup/objects/eb/110fbbf523c3a13fe34a8f1f4fc323e4a1d997": "de9d3dc807c5ef8fdf8884273568c67b",
".git/git_backup/objects/ed/54cbd16ccd935374df535ef3dfd5b15ba69825": "e6b5eeccb61d9a0ab4733e65dd7b7671",
".git/git_backup/objects/ed/b55d4deb8363b6afa65df71d1f9fd8c7787f22": "886ebb77561ff26a755e09883903891d",
".git/git_backup/objects/ee/00a3bea4f41161207ccf3629853837d39d7051": "6dec2e222f8dc0bc254946d6b3fc3565",
".git/git_backup/objects/f1/72c2a222389feb415a211112458c4901433c5a": "e19bf6d505b32a072db6086fabceb266",
".git/git_backup/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/git_backup/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/git_backup/objects/f5/bdbdddd714a1d8a3eb30424a7887d7d41fabab": "9e1d114105f9a6ea5a2146bbf93cf86e",
".git/git_backup/objects/f6/62557105dc1dd16d38bba68decddf86b2e66b5": "1e428a534e6502d2966798b4a96c3d39",
".git/git_backup/objects/f6/beca9163f7f6a2a892b8355bcae0a4e462f477": "25ee83936da859215f1acc4204cff9c6",
".git/git_backup/objects/f8/1be404511a07d6c238fa5887c08571f26b82c9": "81e6103d2384e3569341960727537560",
".git/git_backup/objects/f8/63a510b5bd06abc65eb996c99dfa659fedfd9e": "c2450059d75b58b8efbdc79e6a993973",
".git/git_backup/objects/f9/8b185b7ef51bf4ebaa27f899ec34d6d280b5d3": "095d157b16c9c7dd3096cf61f00616e2",
".git/git_backup/objects/f9/ed58d278b5d78d9ebc26049a67ef238d6a9ea0": "ab5136ea3daf79f89b1b38cdc7de7f44",
".git/git_backup/objects/fb/e32e439253bdeeccaaa04e4389e7918cb6feae": "6e7a650a7c4b8274b5bfb99de55a635e",
".git/git_backup/objects/fd/0b31582f2b1d8f0691240f86e044a3bf98b73d": "471fa931f53e59e9de464d66af29879b",
".git/git_backup/objects/fe/3b987e61ed346808d9aa023ce3073530ad7426": "dc7db10bf25046b27091222383ede515",
".git/git_backup/ORIG_HEAD": "bac88986b908de396dd8977bdf9ceee0",
".git/git_backup/refs/heads/main": "6a8671c8360bb215f8e7bee38c1f1661",
".git/git_backup/refs/remotes/origin/main": "6a8671c8360bb215f8e7bee38c1f1661",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "9c2237fd96d35a6e8df7018182f0ad55",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "c4e96a2a40dc9bf6bef54b0e65222c10",
".git/logs/refs/heads/main": "1156c22e0c1ee41bb4837f6fcf423f69",
".git/logs/refs/remotes/origin/main": "8c0222fc96e67e0e2f65a4eacc13a011",
".git/objects/00/4d3bb375ed58310fec37610c8ef754511c1df9": "4fc5f7d002396e7f35ce3ba3d88b8aaf",
".git/objects/01/90b0670693083a345467816264f7a052ed277a": "96c6c33a3e211e3f2c0f5babbf4ed063",
".git/objects/01/ae5de01a94efa0df5847f3b4b2fa15aba98c98": "2aece61660165cf672e8d022c36a702b",
".git/objects/02/1d4f3579879a4ac147edbbd8ac2d91e2bc7323": "9e9721befbee4797263ad5370cd904ff",
".git/objects/02/909e2b69580d0a9f60f11476e87cbe64af9578": "ae88ab25d5c9b0664998b23fe0253a22",
".git/objects/03/354559d754f448d068522d8e55b8e363495afc": "fbd8843f721eef2d3fec08957eb0e657",
".git/objects/03/74d40b64cb1f1ba3e9ce3c0bbffd25d08c9f68": "aecab20214f7d73b32fa9b9948509e5b",
".git/objects/03/c4ceb936352cd0b45c55ac6fa01c2817680217": "b2bf7f7408252266958f328a1f6f94d3",
".git/objects/08/29ce24f197c9e71fa0d3774e1ac8891d70db61": "75fd148aa03c3067c11355ca3607bb89",
".git/objects/08/f53374bba8d5f8b35f16a4baf5987f3ca7584e": "aeb56b38a746ca8ea900a5e4a70b031f",
".git/objects/09/44fa02de5a15ea347ed99aad09313112a2d30c": "0f6cb93a3b5c83175b50e64e222db022",
".git/objects/09/d268341c144916a2ecc0dfeab7aee8d0109545": "1b64ff4daa8389b88ee97eca446c5494",
".git/objects/0a/b9dcefb373d8d445b1d839d4e9dff11043047b": "0f615436a43052dee935384f8dba50b8",
".git/objects/0b/0bc05e3cbe96cb06ace24c1d4c04005aae6369": "5e68e8afa41b780c66265d1083e604ea",
".git/objects/0c/7eea155af084c761924181e3cefde48309c7f1": "06c2f7a254f8d2ddf81d962a7c3dffad",
".git/objects/0c/81f1322a19b14a67a8a20984234310e8461578": "a5a84f1a2453d046aff3d48c18285057",
".git/objects/0d/7a627ca8e92e5ddac395a1fa1f6ebed8192a21": "038dae8c46bb475670c12c9beb31f810",
".git/objects/0f/2fbe3f668f8b482bf7ffb781203d9df2643c46": "758e8caa0dda146f4b2dd0ed1733e7b1",
".git/objects/0f/44c66f98fcc699a43781ae5ef751770af93603": "92b8544acd372efed39aab80c791de2b",
".git/objects/0f/d52de20d26f7b6de90253360dde5c00cf346f2": "36401d8db48190745d7c2b7dbd2fab38",
".git/objects/11/cb5ea64833c7c9cd0c03be4c9df71db4de3674": "d4ffd51ed86ff3bfb7537a981ae5d8cb",
".git/objects/12/d0b2599441a400dd18f0214f4c72bdaa000192": "3c59c79e418ed72c1d8df7d383bd670f",
".git/objects/12/d5798d4eddf1bfa40342cb630fdc13258368c6": "e3f5dd5911350efc3c49ad02160d1a36",
".git/objects/13/05927fa9e0ce6e04b3186a252b4bfb7cab5ba1": "f1df8a1f9ab78e5a0f81d1c02746eea5",
".git/objects/13/0a54df412615510e14897aad422901ee98a12e": "1ed8afc54b4fe8df4cd7ec24b3e7596e",
".git/objects/13/10300a3af9082838d72b22079520b81fd111b6": "a165eff43487ff89a2142b416eba0624",
".git/objects/16/94a20042903581461d536f908637a23dd464be": "14a2fadbb0930e43e97e6ffecdcfdd04",
".git/objects/17/0ae8bea94c5da46c6f3373a9807eb48c84aa74": "feaa445e57e7770f2037733d05669644",
".git/objects/18/64bea1ad9f7175ca53f4fc55e908fcb43cf527": "e020ca73772a9be115b04c0e67c79ba2",
".git/objects/18/6bf5714ef1c261b2c322c460aecda9dae7278b": "540fbede1688c92fb11bd5289e57557c",
".git/objects/19/1113e5eb4038f908f77ef96045607ced5e01b2": "67858ea0d05c01665d92085c650e5e1b",
".git/objects/19/ceacd38f8fb445236ed358d45e69ac2cd3fb8c": "55bf93e011d9c8541f4de740102b6f28",
".git/objects/1a/3b225db4afd6c4f743bfabfa5aa2b30feb820a": "8ec15525d1121d9ea0a8f3d50cd856b1",
".git/objects/1b/de690e17b7cc2640c9625f23c539d0dcf6e958": "76e44542706ac4709d04b71ead78fd4f",
".git/objects/1f/42d88ada268467ef8a14148ab66e636798453d": "bc4d42d5f9e95c498a7b99c6d1e708cf",
".git/objects/1f/b714104e922376aa4ee2d9860bbdd485f1826f": "43533a8f3a0c5ff384da6b1597818b01",
".git/objects/20/3a3ff5cc524ede7e585dff54454bd63a1b0f36": "4b23a88a964550066839c18c1b5c461e",
".git/objects/23/c828401c021f1f12ac38d432cd2cd83ca64455": "73fcf49ae2cf71155ad8d31133de689d",
".git/objects/23/f7a55d600789070a4cf68d2353f42fb104d5a4": "1bf45bfc16f7372ff1b53abdb65e83ad",
".git/objects/24/61c3a3256c346ef3d42d412f6f3ff08158bc52": "289a14dea56c23925a4fbb3d9311ba5e",
".git/objects/26/1dcffad3b49628b7ff6d59575f3906ce59294f": "102709ec268b4ee4929afdfa6e26273d",
".git/objects/26/5cdc752132241e0f2307e8cd70d39b99cdd473": "8e3ffae9c8a1fe1fe017deab71d25ad0",
".git/objects/26/93695bf50039701317baf1fcb53d60061c43c4": "dcc896bc3d0b8a4648c0fe1bead49ec6",
".git/objects/27/85401a88d234b96b735d0120c54208daa346da": "f633ad3f90a50bdd2166db9b672edbf1",
".git/objects/27/c5a2d8808551dbd1dee164b6d906322f6ae887": "e7f242844c9cfc3d9bb7e47eb6dc6ed7",
".git/objects/28/7a7ec4cdb7135aa5c35f9b7db9112e3e7d5c92": "ced8a4ded2a8da06af728670ba8ae50d",
".git/objects/28/e83a7eb3934ed1fb802cb76b9e2cc74818927f": "af16346d98d973cd634a4b6a55f08732",
".git/objects/29/34a3639d8e588c231df7e7d3ec203f90532856": "a17d81e9c8ac1bf9a36a54b34303d426",
".git/objects/29/f22f56f0c9903bf90b2a78ef505b36d89a9725": "e85914d97d264694217ae7558d414e81",
".git/objects/2a/9165cb126bbaf5ae583640eed30c2dbbceab60": "1d20391defe553fdf36806752c6f9600",
".git/objects/2c/36bf298a649a2edc826a7c4b1ec82cb0c4c47b": "709b15998b126c070deb092927827059",
".git/objects/2d/216cdd90313cb4d391abc89386bae3f65bc660": "3b1ba3f2a3cdfee7671b0c5df3f8f86e",
".git/objects/2d/7aace41480fe8457e0def919fd61f6de737e2a": "009d25c0487a3b970df9aa87de7a6b20",
".git/objects/2d/e9e018b9d1a22448e92669faef7d5533d40750": "f209d4a303c7ac7575505e40983993d7",
".git/objects/2d/eb84ea7a44f43eafbfc41e7ed9e0890df75d05": "6576560ea8d3ee61c920303ff8bb732f",
".git/objects/2e/f9cf26d548966db9967949e75b5fc4d921f0e2": "04cc955487714ac4c2226a1a12cf3cd3",
".git/objects/2f/46cc47a43fb72fefac7daac5df0e8249f14b6a": "5f8e1104567fbb1db303bb49b949a3c3",
".git/objects/2f/792cf3e08f859a59085df50fd36cd318459aec": "7a276e2647b8725b4e97c3a464d586fa",
".git/objects/2f/9c33fde3b4cfd9edbbce54c98f0e56a7796f7f": "64f6a374748539c29814b8aa4d918515",
".git/objects/31/1ef3733c46fadf77f0769b7e333657ee4437b2": "a05cc25c97037cbac78ec5e5710404bd",
".git/objects/31/25e82f132403184418a06fb2e8a22d78151ce7": "0fde801d492e616e162b0ba2547b59aa",
".git/objects/31/53a7e058b1b8b0d8a5269af7963e537e177f95": "8db52aead678443c77db5aba77ffb489",
".git/objects/32/1a77a2f22915abf055e99f0287f894034fdf54": "69b415c93009ce4446d186b55ffc90ba",
".git/objects/32/e9feb0db46e717fba01d4561b8446863a16fc6": "da9e355838a06516aa8d37e45dc3f63c",
".git/objects/32/f7e707247f08534ec64117a19da41c512f7ba1": "dba76249076e23ce99828a9647639e87",
".git/objects/33/7be342eea29bacf5810718703f5648c4410772": "9d0adccd301dbf6a0748289d15523f31",
".git/objects/34/87740e6d4661ea3e360bf5947240e685ad304a": "7d0c29cae176df9c45ad0cb7a1c34f38",
".git/objects/35/34a8f61e91a406941518a71015eab627151b9d": "33aa0d310139208e5be53b4b58072336",
".git/objects/36/c6eda9f66fb26f819a2d09cd56c9e40bd1bbfa": "321db2894b606ca90e6551b98ed4d89b",
".git/objects/37/17b71eaae9c7d90b257c8c0fa88a8a1a908efc": "55b2e07b03752eb637afb0d10ec5007c",
".git/objects/38/f05fd9fdc83963932f5c3248297aaa07103137": "570484ead26a6025398d8e38e83a65bd",
".git/objects/39/741d6ce80a74de30563071c50f8bfa702f5525": "4e51a3aadbbf2d846a256f154665309f",
".git/objects/3b/bdf4a2860db84c4f87f9e143452984064ec960": "cbe53df57d2683f7c63240210e856b4b",
".git/objects/3c/9bafa9b68a6048e5029f5ed790d0c1a51f8fae": "1b9ce335ed2a1c9a98629d8f18f69db0",
".git/objects/3c/cbb65f9913c5c01760e5d791631828b7523bf8": "2c31ebea74618b27910128653ac691c6",
".git/objects/3e/bb1203ec9462d0b37a37f55aeb2af765b099f5": "6b7de00b5e59919832b0137473b10c77",
".git/objects/41/5c059c8094b888b0159fdedfd4e3cb08a8028e": "86914685ccd40e82a7fe5b70459fb9f7",
".git/objects/43/ad435c5659e3deb0b4992c06696b9a3b24d980": "dd5745643b1c3916fda21776ffae87ae",
".git/objects/43/b243d86a6123a5131ea1fd7012755de1010aa8": "c656b4fd56cc122022cbfaa97264fec8",
".git/objects/43/b8651aad72b21af8cab2b6d0e9ac7dd52344e0": "7896e48f6ba01dd93af8e9e250238148",
".git/objects/44/5d0120fa779ed71cc1c36901ee9fc2f36117ef": "46a4bcd256af1f2725f64b0dd4047b85",
".git/objects/44/61f695333e77f3152472eed2712cc7c2edd402": "f86f89547ee047ba1e9994588f276cf5",
".git/objects/44/ff6c8e5e1bf37841a85fdff1f2537872a4295e": "59c474ac1e8938230017788b80b1901f",
".git/objects/45/527c4a19a422180e11e6344024b131544a0037": "1ce77339f5f44c23fedebb078cfee563",
".git/objects/45/d18be5df2ef036a2fa17fcf4f27e60951b4ea6": "3304cac5074848eae5e5443ccb8fa17d",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/46/cc1ffd056476cb899772df183014c237261dd8": "7366ab8a2486ee7b646cae3f473c8fbd",
".git/objects/47/a02a5d2b41357a3eed179dfa94891da9684e18": "6bc8c224cbdc2ca8cee3a6e10745bfd2",
".git/objects/47/a314d063a16a5a722e0d55c9c16a1f7e30be4d": "a8fd4a9f7ef16fa176fab205173b0584",
".git/objects/47/e6b3c4d13f28d1ced91ddd5ebb1136fc0ff1ef": "b3b3aeb63b5979c312aed83d5b54aef5",
".git/objects/48/44816cabe7f19d056ddd3faff212530edad3ba": "b1d37ecbe2bf48021d76babfb4ac7ec8",
".git/objects/4a/745e04e53857313f6aea34405dba32eac1385e": "70c4a2c60bba9e29e4061c1be9e7235c",
".git/objects/4c/f141ea2c6a6134b86f9e263f6ef4c99ae1691a": "9810226d41cefdb7285fc49fbcfd9908",
".git/objects/4d/bf9da7bcce5387354fe394985b98ebae39df43": "534c022f4a0845274cbd61ff6c9c9c33",
".git/objects/4e/1efc732eb80e14d68ceb63e5ccfbef793aeb2d": "3438ea4de8808ceeee55e41de91f63f8",
".git/objects/4f/fbe6ec4693664cb4ff395edf3d949bd4607391": "2beb9ca6c799e0ff64e0ad79f9e55e69",
".git/objects/50/168aca2a2d9c43798201eaf41286dca64fe946": "8d349bc7afe5da8dd8cfceb2353a8bd8",
".git/objects/50/1bbcc15a9c30d2f5ee10e31c74842ac1596de2": "733d58ceed05f5f6816cd561ee8fc893",
".git/objects/50/2b25e379c5ebe9daee629bde16497d9fa91e88": "fdd63a65068f049d83f036611e3601f2",
".git/objects/52/2e5b9453782cd1260a8a4f7979e40c65c1ac62": "30d0e14e1fca96b3679808296d2ed601",
".git/objects/52/9b85336e5b4c19e744d4876be9e3c4cdef886b": "df604164015ae221bd67fcabfdab52bb",
".git/objects/54/6699b9dcbd91b2e7553b2009da64302653e77e": "ba2c0e4748bbb4d5f8921f83655fc8ee",
".git/objects/55/226b9f917742cbc9ef56cb7bc3712477458db4": "6c427e464d3d90ec3d2d8d1c47b0b302",
".git/objects/56/30f1239fca9384e6cd4a8ba8025967c3bbe82d": "60bfb5bd52d566bea440add0b921c3b4",
".git/objects/58/cd5e0d2b5f5d6c9bdd63a1318fa12d79311df8": "5562219ce790c02c083f6fe1b168bdc6",
".git/objects/59/390e09a37851fd145ba9539f9efbcc352aa5c6": "fc8caf3f9eca9438d5e14c2fb0435db1",
".git/objects/5b/8ef6b8ded8726320ab726fe4f4982990e8185f": "5727add066833320be6c3feb678bfe4a",
".git/objects/5c/4b0aaaad8e948468fd65e2deb2307f25b028a7": "c8f2182eb691241bc3cca9e82d33a378",
".git/objects/5c/614bc108c19a03f17520eff14d0a6d0ec29590": "d8fb124eda9370a9144d4d07939fe685",
".git/objects/5c/9079e2cde4b48dd8687fb04e5fcaa1ff6e7bc2": "5956cf483f9cf4373d0b4e69cf989f92",
".git/objects/5f/0ae6785e142d5fb5bffa538995a68752393da6": "3790fb025844860a74f8aa41eae8f75f",
".git/objects/61/0dd252da547db3d681803414daa28739a5e13a": "8336615fe1708db6c1ee7fbf47646fdb",
".git/objects/61/0fa26a0bc360449a84a3ec6a023bb40628c136": "c548c08bfab95ba782622845beede305",
".git/objects/61/5a56bbd29af4f28ca343a426f3710172f81d8f": "5e34285bf5d6fbc26b78b31358eeefec",
".git/objects/61/86fa5ded6d629684efd15d74c7eda23840b4e5": "c28a708d99937195bf28611a233d92ac",
".git/objects/68/5f3180ffa2f6aaeccc6b9822fa1e5edf8c569c": "6aad0ffc9a82b65918395bbaaa0a3e81",
".git/objects/68/a183bff0fcf85bff174ae8ab3962f56c132e67": "b46c06499d9cda6d4871a1014517e0f5",
".git/objects/69/6c025a20e87a5d52aac62db5336221388ef9c0": "cb9bac6fee64c34e0824e1722183c207",
".git/objects/69/7f9f0633c2c94f97b2517e3e8dce9334b6612c": "b57ba7739feeb1751c3f5c7e6ead2dca",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/6c/10618f805920ea04da673525b9565055ee0f57": "3d4ca832ce492f324caf5fbed79d65ba",
".git/objects/6d/9417c6256c13f326bf0a41efe8f6f18af5b4db": "5c3fc4fcfdbc06cefb55d9d7b74ac127",
".git/objects/6f/858c0f0428646ad813db06fd4bac3c1cbbd60f": "522224273588c10a2a878314c9d58adb",
".git/objects/70/0072e8df9b2f5867e16d7a0f446758649a6b4c": "8965a130a829c5ed7f386286f0354e5e",
".git/objects/70/f7f33066fc0e252f0701a0142b1c2a76ff10d1": "5308d686c8473878a01b7e63ca00a996",
".git/objects/71/9171a4ec2cb66af3711929e8529edf4d561e89": "d768a564ced4cc6fdbd23d4983c66316",
".git/objects/72/aaf2ed2852909fb23fc77052b2d9388ab336f3": "73546b49b0babb28e605136d2f13d52b",
".git/objects/73/471fc72f394ba136f5ba9148454531851108fe": "efd51e4e7f090fabcd3d9bd69a503773",
".git/objects/74/7d80887ed7dba1f900d6a0a0bb10d9dcb3a725": "5299c4a063f98d75cf9250d57de8f676",
".git/objects/74/ad3fcea247c0380cb9dbc1c98b0241c8b13db4": "25c86393c067e565113147e63976a96b",
".git/objects/74/ff73d08bea88619e31e42a4df5674026dac89f": "03d2a2c922e195e696a67bb1a62a85af",
".git/objects/76/0ff6af40e4946e3b2734c0e69a6e186ab4d8f4": "009b8f1268bb6c384d233bd88764e6f8",
".git/objects/77/1d83540005b73099078043f8d607d69f76f3ea": "39413eb054b6d0a68606c35427f205a8",
".git/objects/78/0fc35d2a50dd9a6e2d9f12f927a8273ff87c5d": "19bc78c9e88d8b65bb1e1ffccd43a22d",
".git/objects/78/6cdce93c338b59668a5d53c14210a057fe49a0": "01e64d67b15aa63f0dffd1c73d2fbe72",
".git/objects/78/8c592b544db7a2c499b63a8be995aa327d6c78": "7adb91df4482a6abb92ee3255efe49c8",
".git/objects/7a/6c1911dddaea52e2dbffc15e45e428ec9a9915": "f1dee6885dc6f71f357a8e825bda0286",
".git/objects/7b/1f99c3c293fb85b643def10619ce2151cbc50c": "4e0aafc6b4d549035f563ad85c37b096",
".git/objects/7b/eb02a6d9baeaa38e7bffdd9d90b11872f36fb0": "716f8847713ae79445d6fcfcfd85e114",
".git/objects/7c/818ae2bd438901de5a39d4b7385a5a4820478c": "adbe5ae2f2c8e9b74b0fdfb07524b82b",
".git/objects/7d/bb0ad5ad4132f287c7545d0d14d0f767cec691": "9200c60554f7fd3501ffb8360a9ee148",
".git/objects/7d/cb982124b091cda0c0d5528fae87e5a9d42468": "2d707510e7c7751bf680195fd79ff124",
".git/objects/7e/7cb5b1223aa849241a48a1f7bd1b2c5bf5dc44": "8bfe5cc02f6881804900627a5024af53",
".git/objects/7f/90940c244f7cde4b62f7aa818a64c733238282": "126eacf28c0b755d8e4bb2f382335c09",
".git/objects/7f/ddc9084174f8c35c81991a85f42c83ead949c9": "0e0da92ce6dea2d2640c31c3a7623ac9",
".git/objects/81/8c4a80d5632cd97659c2458d86da619bf3c566": "958e115bcf13488d2d328270c8944147",
".git/objects/85/6da8d9c195817812fbc374f93f5aceb4c847b2": "fc398961d6ee1e9c3adc24d5ad62e020",
".git/objects/86/8c472ca598ec1f803c297af4a505557037cf12": "6708da476bbc5804151db0a341aeba2d",
".git/objects/87/6909d9447afa56827d89a86cd03eac7cb0fd62": "6e48db137d1a07b1d12b2a54bef5d393",
".git/objects/87/bb1d5c79f5430cc88a4f25b9b326fab1d5855b": "95f7b7d5c0e8571a540c32995aab5ebd",
".git/objects/88/98c3fc732e2ee3f4153417f1645bd7b79e7400": "ed29cb16c4ce03c3c660076d7aa46b9e",
".git/objects/89/a000e4f4ade79c2bf7b37b5b9e8f44a80cb714": "e6e709ebfd8d830c176af5465d0af9c3",
".git/objects/8b/54a98b65838fd8d50c16d776a27824f0102549": "f649c1cc49ecc2c63d4513a2157fe364",
".git/objects/8b/59d29b9f1e5f4bbf145a917321e27447e0c589": "a2272f2152f8b3b619d327ed9a4252e2",
".git/objects/8b/a9e445b2dc9d6560f716c8ee0e4765fdfeb525": "7873f7eb691315d2e068209bb7438e27",
".git/objects/8b/ca14d88c567ba9275e9011cee8d71263eaab9e": "0d9eab7053e03f08f4147aef96542ecc",
".git/objects/8c/99266130a89547b4344f47e08aacad473b14e0": "41375232ceba14f47b99f9d83708cb79",
".git/objects/8c/9f08b8d9f4817e3527aed8a6137ac10fc90fea": "0e7905b3d45e612b67144e9cbaadf7d4",
".git/objects/8d/f131decc12699ecf178c2e5e72f981ad020b54": "7cb193ead370ef39c93f7317590012ea",
".git/objects/8f/805c3d6a903286be9b87dc3bebc254305ee913": "5dd8aa52fe8de6705a73fd12c6f1db9d",
".git/objects/8f/9294b6eb82af90900a24c055ed854e8bf7c09f": "d68d66d180ee8ee7e29f345dcc765d1e",
".git/objects/8f/ff8ad5dbd8fefc66e549d8edc6bacf371d841e": "6415ea8d64ea6a16ada9b48ea1663ba8",
".git/objects/91/a3d93114fee20d98bdcf72cb566d3303c1a038": "d9ce0b4986600a28163ef9bc01ecf97f",
".git/objects/92/63b6cb891d150d4f55a390cccc64aea6685372": "73267a5155dbe131b3143fa1d9109c1c",
".git/objects/92/c5f66f138d113ee2ce88b49c15184579ccb887": "b83876b51d05204f9b33ba3f4c335cec",
".git/objects/92/eab450609b7dc5d076ddf6c8416de8209373e0": "9b3d4cb7f5916a87f36a18b466ea7ac4",
".git/objects/93/46db2aac6b08d799ed92cdaf24a063dba815ba": "75dd8c07689884b33084b9135790b985",
".git/objects/94/b53972ae76e7879cdeb2c3a0b5f1e2cc0f6257": "90c1e3c987b77408b65264370a26e775",
".git/objects/95/a1c97d5aed5984cc0f0f0534eed1f34559e097": "8fb43a7a3b9dc75b23142094c637c7f6",
".git/objects/96/31ff8ef858a1b22a56d65239d28d42a460930b": "eb6db503feb4135a8f34b7a18127023b",
".git/objects/96/eb9606e9418066efb2af3c42c5d74f9dd4f0a0": "be7c85f8e626a7be1ed98f9f022676e0",
".git/objects/97/10ca823b333a75f38031c7da2d8115ba247059": "c383c1f7b9a3243098966904e0331e14",
".git/objects/97/e7453b92d2f40f9b1d0056bcaa4907f8db61b1": "85ef7afdd5d579ba35c1d478fa3f6c53",
".git/objects/98/0d49437042d93ffa850a60d02cef584a35a85c": "8e18e4c1b6c83800103ff097cc222444",
".git/objects/98/87f058857209bd931506ed814602a40a8cfe8b": "8b55d1cba7c1339ee1ff20d4f4a51e56",
".git/objects/99/901cfbbac6b151a1ccd587a7e0698e21eb1b6a": "6d35835bf1a63e19d7362b179685f445",
".git/objects/9a/0d7ebf5688d338630fa08d96341c9e39f0a176": "65f5cbc4e1bbaf778c34578d9f1e12ec",
".git/objects/9a/8ea8271c5611418ad9fd67c0da822eac3486bc": "8eab58ef642bca4553168741ad5ab21c",
".git/objects/9a/a01ead5d0153d05b0000f529ef91c3aebd6d67": "55bbd6bba6d05303b14802a95e4bb772",
".git/objects/9b/3ef5f169177a64f91eafe11e52b58c60db3df2": "91d370e4f73d42e0a622f3e44af9e7b1",
".git/objects/9d/dba8bfdb4ee7a10418e23c0060a7c7781c05d9": "7940c6d3e13e4fd1f9ce1a2116770d03",
".git/objects/9e/3b4630b3b8461ff43c272714e00bb47942263e": "accf36d08c0545fa02199021e5902d52",
".git/objects/9e/52a2447e172f3527f76fbc575ae2a1614763ee": "d2ecff56075d0a55272de7d73b0c09b4",
".git/objects/9e/ba3a0f16b4e9a93843d4b13c93e37bbca1b143": "6a49b5eebeb367ccf9c7c2f7e4964025",
".git/objects/9e/ef637f810a201692899c15b51f80964d8e2454": "57f74f93c11f83f7fc98bd6aa7626a14",
".git/objects/a0/6f6b17616c8f098dd74119222130dffaa5d278": "919298de2b1b5489afbf19df9194f351",
".git/objects/a0/81c1b40c5c2cfb16ef88f71fb147c464ab5345": "dc6f7bb0c9463fc024ea1443b2c0981f",
".git/objects/a1/1668ba2add893c196cd0a5c46adfe501fdbffa": "bd3cde9d293655c0653eb0036cfaf77e",
".git/objects/a3/cd4040e5a5047de16da8a0561e23bb1e1a1f10": "1a1d8fc7ff845dc23fbaac2d892df980",
".git/objects/a4/32b6e2472277781578775ea1bf5f2f826459e1": "4f89719795dcedae948b20c6158dbcc0",
".git/objects/a4/a84cdf9a0632465027ba57a638a55e981c3618": "fd8f22af4fc7fa17093764f4c6a6a794",
".git/objects/a7/3da57803dda6193bb0bbf0f98c319adf1eac9d": "1bfbb41b119e5a4e7b1aba53085642c3",
".git/objects/a7/a8848201dade78039202dc8dc739f80506e47c": "ee0657dcd557dee7ef157893f094622f",
".git/objects/a8/b066862ca6bbfc0bd805047ecbb3e3e1d02ae0": "67f3cec65a2aee2453aeac10c5f3c1ba",
".git/objects/aa/b30240b05bb2278c589c7c5ba41a02fbe17d73": "ea2461e0fffb0bb01a90d644d4f69497",
".git/objects/ac/0630b6e2d5b74ba6bca0aadcc28b5459d70dbc": "b13e7bce6d598ab944d15cbdec46554c",
".git/objects/ac/560d1523ce7f74c64009a3b43d28d422c02bd7": "c918a8b70adccea924f535955f129b83",
".git/objects/ac/6a28184f1a2369dad68a021b008ce20ef4ab49": "cbe6604636f462b438c85ba204d9b1a7",
".git/objects/ad/1cfa37a1f4e162a6732956fd9c0e88e7e3c018": "a5f7e8349902ffb5df85ad59737f8f54",
".git/objects/ad/4c0ba9842f4de544316a62269732d33f652961": "d2648c4f7ac6a01d24dedabffef3980b",
".git/objects/ad/cdd8eba87e6055e44842cfd4a3f572c781141e": "ce1b031cf84b59dd0a4e46b87f9d7ee9",
".git/objects/ae/15a6ac71e28dbcf70ef07aafc8f5427fcbf342": "2d5e06fb11c3da8d1b580fdf60cfeb31",
".git/objects/af/168c6a21495f254cc48b9900aed4ad63c12a28": "4d8c0a2aa352780344e0a592a986abe5",
".git/objects/af/472b149ac39f5e7798e23a5eb52743831c2464": "97f0a9000bca960b604111b383811fc4",
".git/objects/b4/7c0a44a3ae9f1f5434f5c77a4ef622ddec7a58": "c9c1d69f47ade1d29ba16e15f6c52d09",
".git/objects/b6/b8806f5f9d33389d53c2868e6ea1aca7445229": "b14016efdbcda10804235f3a45562bbf",
".git/objects/b7/7e85ea717770aed8d29d47b3d08911a33607e8": "938b68eb7d906bf6d9e767c22cfe4ddf",
".git/objects/b8/ae968788a881085972fb819616e63ed309789e": "52d231802427654a549afcc4af9e4aa3",
".git/objects/b8/ce8f374088dfec6531debcfe2d83302566f942": "688f12bc6475458107d394ff0f7825a2",
".git/objects/ba/22de39b213fb12caf0cdc63106263e7edae09f": "2579aac378e8331e30f677650864d56b",
".git/objects/ba/6263aa7eaf38f02b53a9c81f1d29cdffc70ad6": "99f712eb0a4809ca8a2d58770495afda",
".git/objects/bc/22b7cba8d94f446ab8ff6114e3d703e68f0a17": "3a9ad5ec7ff1dda6145de3258d8bb609",
".git/objects/be/0c1bbdafdda0aa11a78fb886f80ee4b263b444": "4da085d489eb0de6468b4999492a99ec",
".git/objects/be/adc4f25b34029657549ae3458849a370d0b68d": "3dfb4a97bbcdc7b4a8a0d8c420805f65",
".git/objects/be/f46f12107e3211fd1c2c940eb02288914ee0a1": "44a9ea76a7888def3abd81d0e1772357",
".git/objects/be/fe5f616d80d307ca98f961395f659f7a1466cb": "2b2a6278039e2d88f94b551aacef8f93",
".git/objects/bf/666c775e07a55900e88b901ad96a1d3e5c84e3": "20f47eb4b2b3ac5c4b6d735636533c14",
".git/objects/c0/01b9317820ca7af195653f1f236ed6548450c1": "4c3d089e6d5818da88e00ddae6103cf4",
".git/objects/c0/8ddf4d911184983e04e1380333ed322dbd030a": "159f9760fd03a866ec39f64f47b79199",
".git/objects/c4/016f7d68c0d70816a0c784867168ffa8f419e1": "fdf8b8a8484741e7a3a558ed9d22f21d",
".git/objects/c7/5a63f77a6928d8455db183461c3a0c3d9cbfbd": "2902465c0335bb41bcaedd48238be989",
".git/objects/c7/c094f5009eb8a5c435cac8a8ac124f0cd8f024": "2f78fe921ed5e279a7c02490e2970cf5",
".git/objects/c7/e35da1092c19517ccede9b244aa86c2f25615d": "56773e8f47734c9af0723826eb7df333",
".git/objects/ca/3a7bef1dcf6350d0e5faba4d5ac0afaa522ecf": "7303308a7b2ded6615878c1065a68e38",
".git/objects/ca/3bba02c77c467ef18cffe2d4c857e003ad6d5d": "316e3d817e75cf7b1fd9b0226c088a43",
".git/objects/cc/1d66564c9daeab13394ded42f56b03877f7780": "2a5c0185ed69c2dfe3560cb49a270759",
".git/objects/cd/58a2650dc77cec0518f6f3dcb1e3ab762eb219": "ed3ec8aa323947e002b4f8ba1bdbde55",
".git/objects/cd/dd03f559fd24639dd23e04dbc74834cf0e6334": "a627bbbf350f8f497362935826ec2c5e",
".git/objects/cf/22ce6e9e7ebde567d2607951db345b0cbe0b24": "9461bb6b52576aed2d22268de00fd121",
".git/objects/cf/a3ad2e247c9cc8a84066764e525d0e8b83988d": "dae48181e09430eec4c9e70bd50d9faf",
".git/objects/d0/ce00838a94a316a062a84e5c65f2d887df3be4": "d279469db5025ef3f8ee9d2bf4835a9b",
".git/objects/d1/d1524c272694b3296a9e453a89a3ae40db5c0d": "12ebcc161173dd270ff146651ddc2cab",
".git/objects/d4/2f4cd632911ce3946d2a4554d20da3b32101ca": "c8e7a50aa613d7da5a06b4fbd8b9d610",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d4/c173c25758e946c8b4391e40d0996db2cb4572": "d6929c3e65b52d71846d2d8b30a2c1b9",
".git/objects/d5/80ce749ea55b12b92f5db7747290419c975070": "8b0329dbc6565154a5434e6a0f898fdb",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/d8/1cffb2f4b078a27154171f88e36ad36f6327b4": "de0c2ad32f9858c7a2a178b5082c7970",
".git/objects/d9/ad56692dac1b8762dacb2fc2347bc29b113778": "31c5c7a1cefd7abaa4c9a7a20afbb979",
".git/objects/dc/ef1e23c0739df8ebca37d43263db4dd408ccf4": "67af9cbca61be0fabcf3efdec7e59779",
".git/objects/dd/0b98e2a630639268d92e402e2c3e72eb6d6b8d": "c761ca226bbc90ffeef1131d06f5ed3d",
".git/objects/dd/f0d69d07ca292db82eef16d27d9127d180a1bb": "6179d6384a9268080582f1543f9180b4",
".git/objects/e1/4ef9593f5523d357dd1b8bce1f6f2cbe168592": "a50cb4bdd07733a9ff06921de83f10e7",
".git/objects/e2/6f74f0258310dbc8f8becf4f8c3be1933f3bec": "a3a60b5ba0cc743fcbb4bfdd855d6832",
".git/objects/e2/afe9a39475cfc66eaa9096c2a03de541918dbf": "7ded739249bb3c69ba4d72e355df8e63",
".git/objects/e3/847631ebfae587fc013dd3fb6213acc362c95d": "e2e837de2ba5deffcca29ec110b07961",
".git/objects/e3/e9ee754c75ae07cc3d19f9b8c1e656cc4946a1": "14066365125dcce5aec8eb1454f0d127",
".git/objects/e4/20168b76ae26d8ccdf705cad4d1a18419ae8bc": "ad3f12cb7e705e12a7f09c1471f88ae8",
".git/objects/e5/1c377fe29b177e3a46ecc5596b164c2901f5a0": "aab96fe1599b7c245832af2345526041",
".git/objects/e5/b724ca4432fafe52328530989893484be47687": "698aaba34335f4ae5b0cb29f2fca0d17",
".git/objects/e6/143bd58df53f65514e6a2062cff6e78a3adbb5": "37a8867d73bd2f504faa15d91c2bb370",
".git/objects/e6/99b89ef5961d59e51627a462778adf3e12d8c3": "29760333b92811c96002dd13971c99f9",
".git/objects/e6/9de29bb2d1d6434b8b29ae775ad8c2e48c5391": "c70c34cbeefd40e7c0149b7a0c2c64c2",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/e9/d84fbb34a5af0bf6baa16e243140c9ae072021": "324327fa18e6cdbfb3132bca9f32f2de",
".git/objects/eb/110fbbf523c3a13fe34a8f1f4fc323e4a1d997": "de9d3dc807c5ef8fdf8884273568c67b",
".git/objects/ed/54cbd16ccd935374df535ef3dfd5b15ba69825": "e6b5eeccb61d9a0ab4733e65dd7b7671",
".git/objects/ed/b55d4deb8363b6afa65df71d1f9fd8c7787f22": "886ebb77561ff26a755e09883903891d",
".git/objects/ee/00a3bea4f41161207ccf3629853837d39d7051": "6dec2e222f8dc0bc254946d6b3fc3565",
".git/objects/ee/5ded716e06be4629308b1fef28cca6d6d0f8ed": "0af45dc83c3669865970044c27572c76",
".git/objects/ef/48878cecb6a5dd25bc9df761b48a2b6ae32cf2": "eaec5940af111e06b575a70a8e82db0b",
".git/objects/f1/72c2a222389feb415a211112458c4901433c5a": "e19bf6d505b32a072db6086fabceb266",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/f5/ba4d48aabbd2e356c299b70c4c50d1cbaf3989": "3aad51620745cc24b5697e08e22d6179",
".git/objects/f5/bdbdddd714a1d8a3eb30424a7887d7d41fabab": "9e1d114105f9a6ea5a2146bbf93cf86e",
".git/objects/f6/62557105dc1dd16d38bba68decddf86b2e66b5": "1e428a534e6502d2966798b4a96c3d39",
".git/objects/f6/beca9163f7f6a2a892b8355bcae0a4e462f477": "25ee83936da859215f1acc4204cff9c6",
".git/objects/f7/e095d285eee9239c83804dd8eafb41377c2af4": "9bdf9220c5b18b6c7480d03e877dd172",
".git/objects/f8/1be404511a07d6c238fa5887c08571f26b82c9": "81e6103d2384e3569341960727537560",
".git/objects/f8/63a510b5bd06abc65eb996c99dfa659fedfd9e": "c2450059d75b58b8efbdc79e6a993973",
".git/objects/f9/8b185b7ef51bf4ebaa27f899ec34d6d280b5d3": "095d157b16c9c7dd3096cf61f00616e2",
".git/objects/f9/ed58d278b5d78d9ebc26049a67ef238d6a9ea0": "ab5136ea3daf79f89b1b38cdc7de7f44",
".git/objects/fb/e32e439253bdeeccaaa04e4389e7918cb6feae": "6e7a650a7c4b8274b5bfb99de55a635e",
".git/objects/fc/ad159b52eb62e0841412e4fba92e49d1fcdc76": "13ed52ca6ff0c6ac697eb683d94181c6",
".git/objects/fd/0b31582f2b1d8f0691240f86e044a3bf98b73d": "471fa931f53e59e9de464d66af29879b",
".git/objects/fe/3b987e61ed346808d9aa023ce3073530ad7426": "dc7db10bf25046b27091222383ede515",
".git/ORIG_HEAD": "bac88986b908de396dd8977bdf9ceee0",
".git/refs/heads/main": "cf8fbf6052b52001e6c79c3b43125590",
".git/refs/remotes/origin/main": "6a8671c8360bb215f8e7bee38c1f1661",
"assets/AssetManifest.bin": "c9d2f646b1c9ee47dd58835ac33282fa",
"assets/AssetManifest.bin.json": "962e03f954129a346cae0c09bcf945dc",
"assets/AssetManifest.json": "c3c2dbc628e3bfb1f1a33716fb2674f6",
"assets/assets/images/header11.png": "61a5a29f8c805bab4b62c891cb468c41",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "e7069dfd19b331be16bed984668fe080",
"assets/NOTICES": "c6f5c43fda1d669677eba0449d9cb639",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "b93248a553f9e8bc17f1065929d5934b",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "427a749edcbcb354879a099b6c442772",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "b161610f81c2b5df85ff4ca44cc5d83d",
"icons/Icon-192.png": "427a749edcbcb354879a099b6c442772",
"icons/Icon-512.png": "427a749edcbcb354879a099b6c442772",
"icons/Icon-maskable-192.png": "427a749edcbcb354879a099b6c442772",
"icons/Icon-maskable-512.png": "427a749edcbcb354879a099b6c442772",
"index.html": "83f40ac7848c1a3010925d7bd6ad1158",
"/": "83f40ac7848c1a3010925d7bd6ad1158",
"main.dart.js": "cd4377397146c52f49d703db9d67e625",
"manifest.json": "2eef1b15a67892f29f9340a4e6a96fcf",
"vercel.json": "2ba3654dd08800f8f317b4be4f83b8b5",
"version.json": "122766e089e1f012b0fbb57c4abb66fd"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
