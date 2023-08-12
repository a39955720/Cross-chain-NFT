import { useMoralis, useWeb3Contract } from "react-moralis"
import { crossChainNFTAbi } from "../constants"
import { useEffect, useState } from "react"
import { Card } from "web3uikit"

export default function DisplayNFT() {
    const { isWeb3Enabled, chainId: chainIdHex, account } = useMoralis()
    const chainId = parseInt(chainIdHex)
    const [addressToTokenIds, setAddressToTokenIds] = useState("0")
    const [addressToUris, setAddressToUris] = useState("0")
    const crossChainNFTAddr = "0xf402D559D7a379d342d4c15Eabf756f6Caba402a"

    const { runContractFunction: getAddressToTokenIds } = useWeb3Contract({
        abi: crossChainNFTAbi,
        contractAddress: crossChainNFTAddr,
        functionName: "getAddressToTokenIds",
        params: { owner: account },
    })

    const { runContractFunction: getAddressToUris } = useWeb3Contract({
        abi: crossChainNFTAbi,
        contractAddress: crossChainNFTAddr,
        functionName: "getAddressToUris",
        params: { owner: account },
    })

    async function updateUI() {
        const addressToTokenIdsFromCall = await getAddressToTokenIds()
        const addressToUrisFromCall = await getAddressToUris()
        setAddressToTokenIds(addressToTokenIdsFromCall)
        setAddressToUris(addressToUrisFromCall)
    }

    useEffect(() => {
        const interval = setInterval(updateUI, 500)
        return () => {
            clearInterval(interval)
        }
    }, [isWeb3Enabled, account])

    const cards = []
    if (addressToUris && addressToTokenIds && isWeb3Enabled) {
        for (let i = 0; i < addressToTokenIds.length; i++) {
            const tokenId = addressToTokenIds[i]
            const { title, src } = getSrc(addressToUris[i])
            cards.push(
                <div className="mr-5 mb-10 ml-10">
                    <Card title={title} description={"Token ID : " + tokenId}>
                        <div className="p-2">
                            <div className="flex flex-col items-end gap-2">
                                <img src={src} height="200" width="200" className="my-auto" />
                            </div>
                        </div>
                    </Card>
                </div>,
            )
        }
    }

    function isAddressToTokenIds() {
        if (addressToTokenIds && addressToTokenIds.length == 0) {
            return false
        } else {
            return true
        }
    }

    function getSrc(uri) {
        if (uri === 0) {
            return { title: "Gold", src: "/Gold.png" }
        } else if (uri === 1) {
            return { title: "Silver", src: "/Silver.png" }
        } else if (uri === 2) {
            return { title: "Bronze", src: "/Bronze.png" }
        } else {
            return { title: "xx", src: "/logo.png" }
        }
    }

    return (
        <div className="flex mt-10">
            {isWeb3Enabled && chainId == "5" ? (
                <div>
                    {isAddressToTokenIds() ? (
                        <div className="flex flex-wrap">{cards}</div>
                    ) : (
                        <div className="ml-10 text-xl"> You don't have any NFT!!</div>
                    )}
                </div>
            ) : (
                <div className="ml-10 text-xl">Please connect to wallet and goerli test network </div>
            )}
        </div>
    )
}
