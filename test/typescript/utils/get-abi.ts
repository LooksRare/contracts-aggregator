import * as fs from "fs";
import * as path from "path";

export default async (filename: string) =>
  JSON.parse(fs.readFileSync(path.join(__dirname, `../../../abis/${filename}`), { encoding: "utf8", flag: "r" }));
