import { ConnectButton } from "web3uikit"
import Link from "next/link"

export default function Header() {
    return (
        <nav className="p-5 border-b-10 flex flex-row justify-between items-center bg-red-400">
            <div className="flex items-center">
                <img src="/logo.png" className="my-auto h-20 w-20" />
                <h1 className="py-4 px-4 font-bold text-3xl ml-2">Cross-chain NFT</h1>
            </div>
            <div className="flex flex-row items-center">
                <Link href="/" legacyBehavior>
                    <a className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 mr-4 px-4 rounded ml-auto">
                        Dashboard
                    </a>
                </Link>
                <Link href="/your-nft" legacyBehavior>
                    <a className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 mr-4 px-4 rounded ml-auto">
                        Your NFT
                    </a>
                </Link>
                <ConnectButton moralisAuth={false} />
            </div>
        </nav>
    )
}
