import * as fs from "fs";
import * as path from "path";
import { AbiFunction } from "../interfaces/abi";

export default (filename: string): AbiFunction[] =>
  JSON.parse(fs.readFileSync(path.join(__dirname, `../../../abis/${filename}`), { encoding: "utf8", flag: "r" }));
