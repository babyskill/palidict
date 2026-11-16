plugins {
    id("com.android.asset-pack")
}

assetPack {
    packName.set("core_pack")
    dynamicDelivery {
        deliveryType.set("on-demand")
    }
}
