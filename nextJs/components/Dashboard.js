import { useMoralis, useWeb3Contract } from "react-moralis"
import { fromL1ControlL2Abi, crossChainNFTAbi } from "../constants"
import { useEffect, useState } from "react"
import { useNotification } from "web3uikit"

export default function Dashboard() {
    const { isWeb3Enabled, chainId: chainIdHex, account } = useMoralis()
    const chainId = parseInt(chainIdHex)
    const [balanceOf, setBalanceOf] = useState("0")
    const [status, setStatus] = useState(false)
    const [startMintNFT, setStartMintNFT] = useState(false)
    const [balanceOfPlusOne, setBalanceOfPlusOne] = useState("0")
    const [showModal, setShowModal] = useState(false)
    const [addressToUris, setAddressToUris] = useState("0")
    const [title, setTitle] = useState("0")
    const [src, setSrc] = useState("0")
    const [receiver, setReceiver] = useState("")
    const [tokenId, setTokenId] = useState("")
    const [controllerState, setControllerState] = useState("0")
    const crossChainNFTAddr = "0xf402D559D7a379d342d4c15Eabf756f6Caba402a"
    const fromL1ControlL2Addr = "0xaC50ec06fF01A87D079B2B49fd6FF866AE46668A"
    const dispatch = useNotification()

    const {
        runContractFunction: mintNFT,
        isLoading,
        isFetching,
    } = useWeb3Contract({
        abi: fromL1ControlL2Abi,
        contractAddress: fromL1ControlL2Addr,
        functionName: "mintNFT",
        params: {},
    })

    const { runContractFunction: approve } = useWeb3Contract({
        abi: fromL1ControlL2Abi,
        contractAddress: fromL1ControlL2Addr,
        functionName: "approve",
        params: { to: receiver, tokenId: tokenId },
    })

    const { runContractFunction: transfer } = useWeb3Contract({
        abi: fromL1ControlL2Abi,
        contractAddress: fromL1ControlL2Addr,
        functionName: "transferFrom",
        params: { from: account, to: receiver, tokenId: tokenId },
    })

    const { runContractFunction: getBalanceOf } = useWeb3Contract({
        abi: crossChainNFTAbi,
        contractAddress: crossChainNFTAddr,
        functionName: "balanceOf",
        params: { owner: account },
    })

    const { runContractFunction: getAddressToUris } = useWeb3Contract({
        abi: crossChainNFTAbi,
        contractAddress: crossChainNFTAddr,
        functionName: "getAddressToUris",
        params: { owner: account },
    })

    const { runContractFunction: getControllerState } = useWeb3Contract({
        abi: fromL1ControlL2Abi,
        contractAddress: fromL1ControlL2Addr,
        functionName: "getControllerState",
        params: {},
    })

    const handleSuccess = async function (tx, str) {
        await tx.wait("1")
        handleNewNotification(tx)
        if (str == "mint") {
            setStartMintNFT(true)
        }
    }

    const handleError = async function (error) {
        setStatus(false)
        console.log(error)
    }

    const _mintNFT = async function () {
        setStatus(true)
        setBalanceOfPlusOne(parseInt(balanceOf) + 1)
        await mintNFT({ onSuccess: (tx) => handleSuccess(tx, "mint"), onError: (error) => handleError(error) })
    }

    async function updateUI() {
        const balanceOfFromCall = (await getBalanceOf())?.toString()
        const controllerStateFromCall = (await getControllerState())?.toString()
        const addressToUrisFromCall = await getAddressToUris()
        setBalanceOf(balanceOfFromCall)
        setControllerState(controllerStateFromCall)
        setAddressToUris(addressToUrisFromCall)
        if (balanceOf == balanceOfPlusOne && startMintNFT && addressToUris) {
            setStatus(false)
            setShowModal(true)
            setStartMintNFT(false)
            const { title, src } = getSrc(addressToUris[addressToUris.length - 1])
            setTitle(title)
            setSrc(src)
        }
    }

    useEffect(() => {
        const interval = setInterval(updateUI, 500)

        return () => {
            clearInterval(interval)
        }
    }, [isWeb3Enabled, account, _mintNFT])

    const handleNewNotification = () => {
        dispatch({
            type: "info",
            message: "Transaction Complete!",
            title: "Transaction Notification",
            position: "topR",
            icon: "bell",
        })
    }

    function getSrc(uri) {
        if (uri === 0) {
            return { title: "Gold NFT !!", src: "/Gold.png" }
        } else if (uri === 1) {
            return { title: "Silver NFT!!", src: "/Silver.png" }
        } else if (uri === 2) {
            return { title: "Bronze NFT!!", src: "/Bronze.png" }
        } else {
            return { title: "xx", src: "/logo.png" }
        }
    }

    return (
        <div className="p-5 font-bold">
            {isWeb3Enabled && chainId == "5" ? (
                <>
                    <div className="text-xl">
                        ------------------------------------------------------------------------------------------------------------------------
                    </div>
                    <div className="flex items-start mt-10">
                        <div className="ml-10 mt-1 text-xl"> Mint NFT: </div>
                        <button
                            className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded ml-5"
                            onClick={async function () {
                                await _mintNFT()
                            }}
                            disabled={isLoading || isFetching || status || controllerState == 1}
                        >
                            {isLoading || isFetching || status || controllerState == 1 ? (
                                <div className="animate-spin spinner-border h-8 w-8 border-b-2 rounded-full"></div>
                            ) : (
                                "MINT"
                            )}
                        </button>
                        {showModal && (
                            <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50">
                                <div className="bg-white p-5 rounded">
                                    <h2 className="text-2xl mb-4">{"You Mint " + title}</h2>
                                    <img src={src} height="200" width="200" className="my-auto" />
                                    <button
                                        className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded mt-4"
                                        onClick={() => setShowModal(false)}
                                    >
                                        Close
                                    </button>
                                </div>
                            </div>
                        )}
                    </div>
                    <div className="text-xl mt-10">
                        ------------------------------------------------------------------------------------------------------------------------
                    </div>
                    <div className="flex flex-col items-start mt-10">
                        <div className="ml-10 text-xl"> Transfer NFT: </div>
                        <div className="flex ml-5 mt-5 items-start">
                            <div className="ml-10 mt-1 text-xl"> Receiver: </div>
                            <input
                                type="text"
                                className="ml-5 border border-gray-300 px-4 py-2 rounded-md focus:outline-none focus:ring focus:border-blue-500"
                                value={receiver}
                                onChange={(e) => setReceiver(e.target.value)}
                            />
                            <div className="ml-10 mt-1 text-xl"> Token ID: </div>
                            <input
                                type="text"
                                className="ml-5 border border-gray-300 px-4 py-2 rounded-md focus:outline-none focus:ring focus:border-blue-500"
                                value={tokenId}
                                onChange={(e) => setTokenId(e.target.value)}
                            />
                            <button
                                className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded ml-10"
                                onClick={async function () {
                                    await approve({
                                        onSuccess: (tx) => handleSuccess(tx),
                                        onError: (error) => handleError(error),
                                    })
                                }}
                            >
                                Approve
                            </button>
                            <button
                                className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded ml-10"
                                onClick={async function () {
                                    await transfer({
                                        onSuccess: (tx) => handleSuccess(tx),
                                        onError: (error) => handleError(error),
                                    })
                                }}
                            >
                                Transfer
                            </button>
                        </div>
                    </div>
                    <div className="text-xl mt-5">
                        ------------------------------------------------------------------------------------------------------------------------
                    </div>
                    <div className="text-xl mt-10 ml-10">Description:</div>
                    <div className="text-lg mt-2 ml-10">
                        When you mint an NFT, it will be synchronized across the Goerli chain, Optimism chain, Base
                        chain, and Zora chain. (Layer 2 chains may require a waiting time of 1 to 5 minutes for
                        synchronization.)
                    </div>
                    <div className="text-lg mt-2 ml-10">
                        If you want to transfer, you need to click the "Approve" button first, wait for the transaction
                        to be successful, and then click the "Transfer" button.
                    </div>
                    <div className="text-lg mt-2 ml-10">
                        After successfully minting, you can click on the "Your NFT" button in the top left corner to
                        navigate to the page where you can view your NFT.
                    </div>
                    <div className="text-lg mt-2 ml-10">
                        Alternatively, you can check the status of your NFT on different chains by visiting{" "}
                        <a href="https://testnets.opensea.io/zh-TW/account/collected" style={{ color: "blue" }}>
                            OpenSea
                        </a>
                        .
                    </div>
                    <div className="text-xl mt-10 ml-10">NFT Address:</div>
                    <div className="text-lg mt-2 ml-10">
                        Goerli Testnet:{" "}
                        <a
                            href="https://goerli.etherscan.io/address/0xf402D559D7a379d342d4c15Eabf756f6Caba402a"
                            style={{ color: "blue" }}
                        >
                            0xf402D559D7a379d342d4c15Eabf756f6Caba402a
                        </a>
                    </div>
                    <div className="text-lg mt-2 ml-10">
                        Optimism Goerli:{" "}
                        <a
                            href="https://goerli-optimism.etherscan.io/address/0x047eEf6502D028A8970e7e6B257a2510Bd2Cd607"
                            style={{ color: "blue" }}
                        >
                            0x047eEf6502D028A8970e7e6B257a2510Bd2Cd607
                        </a>
                    </div>
                    <div className="text-lg mt-2 ml-10">
                        Base Goerli:{" "}
                        <a
                            href="https://goerli.basescan.org/address/0xc714490b883bd62b228439dd9c7e314ce8504852"
                            style={{ color: "blue" }}
                        >
                            0xC714490B883bd62b228439DD9C7e314Ce8504852
                        </a>
                    </div>
                    <div className="text-lg mt-2 ml-10">
                        Zora Goerli:{" "}
                        <a
                            href="https://testnet.explorer.zora.energy/address/0xB23748bdf3972adf0e8C3f77F1E9b1F5292cc42F"
                            style={{ color: "blue" }}
                        >
                            0xB23748bdf3972adf0e8C3f77F1E9b1F5292cc42F
                        </a>
                    </div>
                    <div className="h-20"></div>
                </>
            ) : (
                <div className="ml-10 text-xl">Please connect to wallet and goerli test network </div>
            )}
        </div>
    )
}
