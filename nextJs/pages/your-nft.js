import Head from "next/head"
import Image from "next/image"
import styles from "../styles/Home.module.css"
import Header from "../components/Header"
import DisplayNFT from "../components/DisplayNFT"

export default function Home() {
    return (
        <div className="bg-yellow-400 flex-col min-h-screen">
            <Head>
                <title>Cross-chain NFT</title>
                <meta name="description" content="A Cross-chain NFT project" />
                <link rel="icon" href="/logo1.png" />
            </Head>
            <Header />
            <DisplayNFT />
        </div>
    )
}
